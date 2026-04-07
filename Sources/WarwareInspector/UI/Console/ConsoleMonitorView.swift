import SwiftUI

struct ConsoleMonitorView: View {
    @Bindable var store: InspectorStore

    @State private var selectedLogType: LogType?
    @State private var searchText: String = ""

    private var filteredLogs: [LogEntry] {
        var logs = store.logEntries

        if let type = selectedLogType {
            logs = logs.filter { $0.type == type }
        }

        if !searchText.isEmpty {
            logs = logs.filter { log in
                log.message.localizedCaseInsensitiveContains(searchText) ||
                (log.file?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (log.function?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (log.location?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return logs.reversed()
    }

    var body: some View {
        Group {
            if filteredLogs.isEmpty {
                EmptyStateView(
                    title: "No console logs",
                    systemImage: "text.alignleft",
                    description: "Print statements will appear here as the app runs"
                )
            } else {
                List {
                    ForEach(filteredLogs) { log in
                        ConsoleLogRowView(log: log)
                            .listRowInsets(EdgeInsets(top: InspectorTheme.Spacing.xs, leading: InspectorTheme.Spacing.md, bottom: InspectorTheme.Spacing.xs, trailing: InspectorTheme.Spacing.md))
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.insetGrouped)
                .contentMargins(.top, InspectorTheme.Spacing.lg)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                FilterChipBarView(chips: filterChips)
                Divider()
            }
        }
        .searchable(text: $searchText, prompt: "Search in console logs...")
    }

    private var filterChips: [ChipItem] {
        var chips: [ChipItem] = [
            ChipItem(
                title: "All",
                count: store.logEntries.count,
                isSelected: selectedLogType == nil
            ) { selectedLogType = nil }
        ]

        for type in LogType.allCases {
            let count = store.logEntries.filter { $0.type == type }.count
            chips.append(
                ChipItem(
                    title: type.rawValue,
                    count: count,
                    icon: type.systemImage,
                    color: type.color,
                    isSelected: selectedLogType == type
                ) { selectedLogType = type }
            )
        }

        return chips
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Console - With Logs") {
    NavigationStack {
        ConsoleMonitorView(store: .consoleOnly)
            .navigationTitle("Console")
    }
}

#Preview("Console - Empty") {
    NavigationStack {
        ConsoleMonitorView(store: InspectorStore())
            .navigationTitle("Console")
    }
}
#endif
