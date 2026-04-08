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
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.lg) {
            if isLoading {
                ProgressView()
                    .tint(InspectorTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, InspectorTheme.Spacing.xxl)
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
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
            Text("TABLES")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: InspectorTheme.Spacing.sm) {
                    ForEach(tables) { table in
                        Button {
                            selectTable(table)
                        } label: {
                            HStack(spacing: InspectorTheme.Spacing.xs) {
                                Text(table.name)
                                    .font(InspectorTheme.Typography.code)
                                    .lineLimit(1)

                                Text("\(table.rowCount)")
                                    .font(InspectorTheme.Typography.detail)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(
                                selectedTable?.name == table.name
                                    ? InspectorTheme.Colors.accent
                                    : InspectorTheme.Colors.textSecondary
                            )
                            .padding(.horizontal, InspectorTheme.Spacing.md)
                            .padding(.vertical, InspectorTheme.Spacing.sm)
                            .background(
                                selectedTable?.name == table.name
                                    ? InspectorTheme.Colors.accent.opacity(0.15)
                                    : InspectorTheme.Colors.surface
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
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
            HStack {
                Text(table.name.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)

                Spacer()

                Text("\(rows.count)\(rows.count >= 100 ? "+" : "") of \(table.rowCount) rows")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }

            if rows.isEmpty {
                Text("Empty table")
                    .font(InspectorTheme.Typography.body)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, InspectorTheme.Spacing.xl)
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(spacing: 0) {
                        // Header row
                        HStack(spacing: 0) {
                            ForEach(table.columns, id: \.self) { col in
                                Text(col)
                                    .font(InspectorTheme.Typography.detail)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(InspectorTheme.Colors.textSecondary)
                                    .frame(width: columnWidth(for: col, in: table), alignment: .leading)
                                    .padding(.horizontal, InspectorTheme.Spacing.sm)
                                    .padding(.vertical, InspectorTheme.Spacing.sm)
                            }
                        }
                        .background(InspectorTheme.Colors.surfaceElevated)

                        Divider().overlay(InspectorTheme.Colors.border)

                        // Data rows
                        ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                            HStack(spacing: 0) {
                                ForEach(table.columns, id: \.self) { col in
                                    Text(row[col] ?? "")
                                        .font(InspectorTheme.Typography.code)
                                        .foregroundStyle(cellColor(for: row[col]))
                                        .lineLimit(2)
                                        .frame(width: columnWidth(for: col, in: table), alignment: .leading)
                                        .padding(.horizontal, InspectorTheme.Spacing.sm)
                                        .padding(.vertical, InspectorTheme.Spacing.xs)
                                }
                            }
                            .background(index % 2 == 0 ? Color.clear : InspectorTheme.Colors.surface.opacity(0.5))

                            if index < rows.count - 1 {
                                Divider().overlay(InspectorTheme.Colors.border.opacity(0.5))
                            }
                        }
                    }
                }
                .background(InspectorTheme.Colors.surface)
                .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: InspectorTheme.Radius.md)
                        .stroke(InspectorTheme.Colors.border, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: InspectorTheme.Spacing.sm) {
            Image(systemName: "cylinder")
                .font(.system(size: 28))
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
            Text("No tables found")
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, InspectorTheme.Spacing.xl)
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
        guard let value else { return InspectorTheme.Colors.textTertiary }
        if value == "NULL" { return InspectorTheme.Colors.textTertiary }
        if value.hasPrefix("[BLOB:") { return InspectorTheme.Colors.syntaxNumber }
        if Int64(value) != nil || Double(value) != nil { return InspectorTheme.Colors.syntaxNumber }
        return InspectorTheme.Colors.textPrimary
    }
}
