import SwiftUI
import SQLite3

// MARK: - SQLite Reader (lightweight, read-only)

struct SQLiteTable: Identifiable {
    let id = UUID()
    let name: String
    let rowCount: Int
    let columns: [String]
}

/// A cell value with both display text and optional raw data (for BLOBs).
struct SQLiteCellValue {
    let display: String
    let blobData: Data?
    let color: ValueColor

    enum ValueColor {
        case text, number, null, blob
    }

    var isBlob: Bool { blobData != nil }
}

struct SQLiteReader {
    let path: String

    func readTables() -> [SQLiteTable] {
        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_close(db) }

        var tables: [SQLiteTable] = []
        var stmt: OpaquePointer?

        // Get all user tables
        let query = "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let namePtr = sqlite3_column_text(stmt, 0) else { continue }
            let name = String(cString: namePtr)
            let columns = readColumns(db: db, table: name)
            let count = readRowCount(db: db, table: name)
            tables.append(SQLiteTable(name: name, rowCount: count, columns: columns))
        }

        return tables
    }

    func readRows(table: String, limit: Int = 100) -> [[String: SQLiteCellValue]] {
        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        let query = "SELECT * FROM \"\(table)\" LIMIT \(limit)"
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        let colCount = Int(sqlite3_column_count(stmt))
        var columns: [String] = []
        for i in 0..<colCount {
            if let namePtr = sqlite3_column_name(stmt, Int32(i)) {
                columns.append(String(cString: namePtr))
            }
        }

        var rows: [[String: SQLiteCellValue]] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String: SQLiteCellValue] = [:]
            for i in 0..<colCount {
                let col = columns[i]
                let index = Int32(i)

                switch sqlite3_column_type(stmt, index) {
                case SQLITE_NULL:
                    row[col] = SQLiteCellValue(display: "NULL", blobData: nil, color: .null)

                case SQLITE_INTEGER:
                    let value = String(sqlite3_column_int64(stmt, index))
                    row[col] = SQLiteCellValue(display: value, blobData: nil, color: .number)

                case SQLITE_FLOAT:
                    let value = String(sqlite3_column_double(stmt, index))
                    row[col] = SQLiteCellValue(display: value, blobData: nil, color: .number)

                case SQLITE_BLOB:
                    let bytes = Int(sqlite3_column_bytes(stmt, index))
                    var data = Data()
                    if bytes > 0, let ptr = sqlite3_column_blob(stmt, index) {
                        data = Data(bytes: ptr, count: bytes)
                    }
                    row[col] = SQLiteCellValue(
                        display: "BLOB \(bytes) B",
                        blobData: data,
                        color: .blob
                    )

                default:
                    if let textPtr = sqlite3_column_text(stmt, index) {
                        let text = String(cString: textPtr)
                        let truncated = text.count > 200 ? String(text.prefix(200)) + "..." : text
                        row[col] = SQLiteCellValue(display: truncated, blobData: nil, color: .text)
                    } else {
                        row[col] = SQLiteCellValue(display: "", blobData: nil, color: .text)
                    }
                }
            }
            rows.append(row)
        }

        return rows
    }

    private func readColumns(db: OpaquePointer?, table: String) -> [String] {
        var stmt: OpaquePointer?
        let query = "PRAGMA table_info(\"\(table)\")"
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        var columns: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let namePtr = sqlite3_column_text(stmt, 1) {
                columns.append(String(cString: namePtr))
            }
        }
        return columns
    }

    private func readRowCount(db: OpaquePointer?, table: String) -> Int {
        var stmt: OpaquePointer?
        let query = "SELECT COUNT(*) FROM \"\(table)\""
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }

        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int64(stmt, 0))
        }
        return 0
    }
}

// MARK: - SQLite Viewer View

struct SQLiteViewerView: View {
    let path: String

    @State private var tables: [SQLiteTable] = []
    @State private var selectedTable: SQLiteTable?
    @State private var rows: [[String: SQLiteCellValue]] = []
    @State private var isLoading = true
    @State private var inspectingBlob: BlobInspection?

    private let reader: SQLiteReader

    init(path: String) {
        self.path = path
        self.reader = SQLiteReader(path: path)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.lg) {
            if isLoading {
                ProgressView()
                    .tint(PryTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, PryTheme.Spacing.xxl)
            } else if tables.isEmpty {
                emptyState
            } else {
                tableList
                if let selected = selectedTable {
                    dataTable(for: selected)
                }
            }
        }
        .task {
            tables = reader.readTables()
            if let first = tables.first {
                selectTable(first)
            }
            isLoading = false
        }
        .sheet(item: $inspectingBlob) { blob in
            BlobInspectorView(column: blob.column, data: blob.data)
        }
    }

    // MARK: - Table Picker

    private var tableList: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
            Text("TABLES")
                .font(PryTheme.Typography.sectionLabel)
                .tracking(PryTheme.Text.tracking)
                .foregroundStyle(PryTheme.Colors.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PryTheme.Spacing.sm) {
                    ForEach(tables) { table in
                        Button {
                            selectTable(table)
                        } label: {
                            HStack(spacing: PryTheme.Spacing.xs) {
                                Text(table.name)
                                    .font(PryTheme.Typography.code)
                                    .lineLimit(1)

                                Text("\(table.rowCount)")
                                    .font(PryTheme.Typography.detail)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(
                                selectedTable?.name == table.name
                                    ? PryTheme.Colors.accent
                                    : PryTheme.Colors.textSecondary
                            )
                            .padding(.horizontal, PryTheme.Spacing.md)
                            .padding(.vertical, PryTheme.Spacing.sm)
                            .background(
                                selectedTable?.name == table.name
                                    ? PryTheme.Colors.accent.opacity(PryTheme.Opacity.badge)
                                    : PryTheme.Colors.surface
                            )
                            .clipShape(.capsule)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Data Table

    private func dataTable(for table: SQLiteTable) -> some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
            HStack {
                Text(table.name.uppercased())
                    .font(PryTheme.Typography.sectionLabel)
                    .tracking(PryTheme.Text.tracking)
                    .foregroundStyle(PryTheme.Colors.textTertiary)

                Spacer()

                Text("\(rows.count)\(rows.count >= 100 ? "+" : "") of \(table.rowCount) rows")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }

            if rows.isEmpty {
                Text("Empty table")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PryTheme.Spacing.xl)
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(spacing: 0) {
                        // Header row
                        HStack(spacing: 0) {
                            ForEach(table.columns, id: \.self) { col in
                                Text(col)
                                    .font(PryTheme.Typography.detail)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(PryTheme.Colors.textSecondary)
                                    .frame(width: columnWidth(for: col, in: table), alignment: .leading)
                                    .padding(.horizontal, PryTheme.Spacing.sm)
                                    .padding(.vertical, PryTheme.Spacing.sm)
                            }
                        }
                        .background(PryTheme.Colors.surfaceElevated)

                        Divider().overlay(PryTheme.Colors.border)

                        // Data rows
                        ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                            HStack(spacing: 0) {
                                ForEach(table.columns, id: \.self) { col in
                                    cellView(value: row[col], column: col, table: table)
                                }
                            }
                            .background(index % 2 == 0 ? Color.clear : PryTheme.Colors.surface.opacity(PryTheme.Opacity.overlay))

                            if index < rows.count - 1 {
                                Divider().overlay(PryTheme.Colors.border.opacity(PryTheme.Opacity.overlay))
                            }
                        }
                    }
                }
                .background(PryTheme.Colors.surface)
                .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: PryTheme.Radius.md)
                        .stroke(PryTheme.Colors.border, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: PryTheme.Spacing.sm) {
            Image(systemName: "cylinder")
                .font(.system(size: PryTheme.FontSize.emptyState))
                .foregroundStyle(PryTheme.Colors.textTertiary)
            Text("No tables found")
                .font(PryTheme.Typography.body)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PryTheme.Spacing.xl)
    }

    // MARK: - Helpers

    private func selectTable(_ table: SQLiteTable) {
        selectedTable = table
        rows = reader.readRows(table: table.name)
    }

    @ViewBuilder
    private func cellView(value: SQLiteCellValue?, column: String, table: SQLiteTable) -> some View {
        if let value, value.isBlob, let data = value.blobData {
            Button {
                inspectingBlob = BlobInspection(column: column, data: data)
            } label: {
                Text(value.display)
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.accent)
                    .underline()
                    .lineLimit(1)
                    .frame(width: columnWidth(for: column, in: table), alignment: .leading)
                    .padding(.horizontal, PryTheme.Spacing.sm)
                    .padding(.vertical, PryTheme.Spacing.xs)
            }
            .buttonStyle(.plain)
        } else {
            Text(value?.display ?? "")
                .font(PryTheme.Typography.code)
                .foregroundStyle(cellColor(for: value))
                .lineLimit(2)
                .frame(width: columnWidth(for: column, in: table), alignment: .leading)
                .padding(.horizontal, PryTheme.Spacing.sm)
                .padding(.vertical, PryTheme.Spacing.xs)
        }
    }

    private func columnWidth(for column: String, in table: SQLiteTable) -> CGFloat {
        let headerWidth = CGFloat(column.count) * 8 + 24
        let maxDataWidth: CGFloat = rows.prefix(20).reduce(0) { maxW, row in
            let text = row[column]?.display ?? ""
            return max(maxW, CGFloat(min(text.count, 30)) * 7 + 24)
        }
        return max(min(max(headerWidth, maxDataWidth), 250), 80)
    }

    private func cellColor(for value: SQLiteCellValue?) -> Color {
        guard let value else { return PryTheme.Colors.textTertiary }
        switch value.color {
        case .null: return PryTheme.Colors.textTertiary
        case .number: return PryTheme.Colors.syntaxNumber
        case .blob: return PryTheme.Colors.syntaxNumber
        case .text: return PryTheme.Colors.textPrimary
        }
    }
}

// MARK: - Blob Inspection

struct BlobInspection: Identifiable {
    let id = UUID()
    let column: String
    let data: Data
}

struct BlobInspectorView: View {
    let column: String
    let data: Data

    @Environment(\.dismiss) private var dismiss

    enum DecodedFormat {
        case plist(String)
        case json(String)
        case text(String)
        case image(UIImage)
        case hex(String)
    }

    private var decoded: DecodedFormat {
        // Binary plist
        if data.count >= 6 {
            let bytes = [UInt8](data.prefix(6))
            if bytes.starts(with: [0x62, 0x70, 0x6C, 0x69, 0x73, 0x74]) {
                if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) {
                    let sanitized = sanitizePlist(plist)
                    if JSONSerialization.isValidJSONObject(sanitized),
                       let jsonData = try? JSONSerialization.data(withJSONObject: sanitized, options: [.prettyPrinted, .sortedKeys]),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        return .plist(jsonString)
                    }
                    return .plist(String(describing: plist))
                }
            }
        }

        // Image magic bytes
        if data.count >= 4 {
            let bytes = [UInt8](data.prefix(4))
            let isImage = bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) || // PNG
                          bytes.starts(with: [0xFF, 0xD8, 0xFF]) ||        // JPEG
                          bytes.starts(with: [0x47, 0x49, 0x46])           // GIF
            if isImage, let image = UIImage(data: data) {
                return .image(image)
            }
        }

        // JSON
        if let jsonObj = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObj, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: prettyData, encoding: .utf8) {
            return .json(jsonString)
        }

        // UTF-8 text
        if let text = String(data: data, encoding: .utf8),
           !text.isEmpty,
           text.allSatisfy({ $0.isASCII || $0.isLetter }) {
            return .text(text)
        }

        // Hex dump fallback
        return .hex(hexDump(data))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.lg) {
                    metadataBanner

                    switch decoded {
                    case .plist(let text):
                        sectionLabel("BINARY PLIST (decoded)")
                        CodeBlockView(text: text, language: .json)
                    case .json(let text):
                        sectionLabel("JSON")
                        CodeBlockView(text: text, language: .json)
                    case .text(let text):
                        sectionLabel("TEXT")
                        CodeBlockView(text: text, language: .text)
                    case .image(let image):
                        sectionLabel("IMAGE")
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                        Text("\(Int(image.size.width))x\(Int(image.size.height))")
                            .font(PryTheme.Typography.detail)
                            .foregroundStyle(PryTheme.Colors.textTertiary)
                    case .hex(let text):
                        sectionLabel("HEX DUMP (binary data)")
                        CodeBlockView(text: text, language: .text)
                    }
                }
                .padding(.horizontal, PryTheme.Spacing.lg)
                .padding(.vertical, PryTheme.Spacing.md)
            }
            .pryBackground()
            .navigationTitle(column)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(PryTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private var metadataBanner: some View {
        HStack(spacing: PryTheme.Spacing.sm) {
            Image(systemName: "doc.zipper")
                .foregroundStyle(PryTheme.Colors.syntaxNumber)
            Text("\(data.count) bytes")
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
            Spacer()
            Text(formatName)
                .font(PryTheme.Typography.codeSmall)
                .fontWeight(.bold)
                .foregroundStyle(PryTheme.Colors.accent)
        }
        .padding(PryTheme.Spacing.md)
        .background(PryTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
    }

    private var formatName: String {
        switch decoded {
        case .plist: "BPLIST"
        case .json: "JSON"
        case .text: "TEXT"
        case .image: "IMAGE"
        case .hex: "BINARY"
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(PryTheme.Typography.sectionLabel)
            .tracking(PryTheme.Text.tracking)
            .foregroundStyle(PryTheme.Colors.textTertiary)
    }

    private func sanitizePlist(_ value: Any) -> Any {
        switch value {
        case let dict as [String: Any]:
            return dict.mapValues { sanitizePlist($0) }
        case let array as [Any]:
            return array.map { sanitizePlist($0) }
        case let date as Date:
            return date.formatted(.iso8601)
        case let data as Data:
            return "[Data: \(data.count) bytes]"
        default:
            return value
        }
    }

    private func hexDump(_ data: Data, maxBytes: Int = 512) -> String {
        let limited = data.prefix(maxBytes)
        var lines: [String] = []
        let bytesPerLine = 16

        for offset in stride(from: 0, to: limited.count, by: bytesPerLine) {
            let end = min(offset + bytesPerLine, limited.count)
            let chunk = limited[limited.index(limited.startIndex, offsetBy: offset)..<limited.index(limited.startIndex, offsetBy: end)]
            let address = String(format: "%08X", offset)
            let hex = chunk.map { String(format: "%02X", $0) }.joined(separator: " ").padding(toLength: bytesPerLine * 3 - 1, withPad: " ", startingAt: 0)
            let ascii = chunk.map { (byte: UInt8) -> String in
                (byte >= 0x20 && byte < 0x7F) ? String(UnicodeScalar(byte)) : "."
            }.joined()
            lines.append("\(address)  \(hex)  |\(ascii)|")
        }

        if data.count > maxBytes {
            lines.append("")
            lines.append("... \(data.count - maxBytes) more bytes")
        }

        return lines.joined(separator: "\n")
    }
}
