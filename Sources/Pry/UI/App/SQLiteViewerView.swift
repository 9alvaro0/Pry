import SwiftUI
import SQLite3

// MARK: - SQLite Reader (lightweight, read-only)

struct SQLiteTable: Identifiable {
    let id = UUID()
    let name: String
    let rowCount: Int
    let columns: [String]
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

    func readRows(table: String, limit: Int = 100) -> [[String: String]] {
        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        // Table name is from sqlite_master, not user input — safe to interpolate
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

        var rows: [[String: String]] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String: String] = [:]
            for i in 0..<colCount {
                let col = columns[i]
                switch sqlite3_column_type(stmt, Int32(i)) {
                case SQLITE_NULL:
                    row[col] = "NULL"
                case SQLITE_INTEGER:
                    row[col] = String(sqlite3_column_int64(stmt, Int32(i)))
                case SQLITE_FLOAT:
                    row[col] = String(sqlite3_column_double(stmt, Int32(i)))
                case SQLITE_BLOB:
                    let bytes = sqlite3_column_bytes(stmt, Int32(i))
                    row[col] = "[BLOB: \(bytes) bytes]"
                default:
                    if let textPtr = sqlite3_column_text(stmt, Int32(i)) {
                        let text = String(cString: textPtr)
                        row[col] = text.count > 200 ? String(text.prefix(200)) + "..." : text
                    } else {
                        row[col] = ""
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
    @State private var rows: [[String: String]] = []
    @State private var isLoading = true

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
                                    Text(row[col] ?? "")
                                        .font(PryTheme.Typography.code)
                                        .foregroundStyle(cellColor(for: row[col]))
                                        .lineLimit(2)
                                        .frame(width: columnWidth(for: col, in: table), alignment: .leading)
                                        .padding(.horizontal, PryTheme.Spacing.sm)
                                        .padding(.vertical, PryTheme.Spacing.xs)
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

    private func columnWidth(for column: String, in table: SQLiteTable) -> CGFloat {
        // Estimate width based on column name and sample data
        let headerWidth = CGFloat(column.count) * 8 + 24
        let maxDataWidth: CGFloat = rows.prefix(20).reduce(0) { maxW, row in
            let text = row[column] ?? ""
            return max(maxW, CGFloat(min(text.count, 30)) * 7 + 24)
        }
        return max(min(max(headerWidth, maxDataWidth), 250), 80)
    }

    private func cellColor(for value: String?) -> Color {
        guard let value else { return PryTheme.Colors.textTertiary }
        if value == "NULL" { return PryTheme.Colors.textTertiary }
        if value.hasPrefix("[BLOB:") { return PryTheme.Colors.syntaxNumber }
        if Int64(value) != nil || Double(value) != nil { return PryTheme.Colors.syntaxNumber }
        return PryTheme.Colors.textPrimary
    }
}
