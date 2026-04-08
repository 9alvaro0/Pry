import SwiftUI
import UIKit

struct ConsoleMonitorView: View {
    @Bindable var store: InspectorStore

    @State private var selectedLogType: LogType?
    @State private var searchText: String = ""
    @State private var showCopiedAll = false

    private var filteredLogs: [LogEntry] {
        var logs = store.logEntries

        if let type = selectedLogType {
            logs = logs.filter { $0.type == type }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            logs = logs.filter { log in
                log.message.lowercased().contains(query) ||
                log.type.rawValue.lowercased().contains(query) ||
                (log.file?.lowercased().contains(query) ?? false) ||
                (log.function?.lowercased().contains(query) ?? false) ||
                (log.location?.lowercased().contains(query) ?? false)
            }
        }

        return logs.reversed()
    }

    private var typeCounts: [LogType: Int] {
        var counts: [LogType: Int] = [:]
        for log in store.logEntries {
            counts[log.type, default: 0] += 1
        }
        return counts
    }

    var body: some View {
        Group {
            if store.logEntries.isEmpty {
                EmptyStateView(
                    title: "No console logs",
                    systemImage: "text.alignleft",
                    description: "Logs will appear here as the app runs"
                )
            } else {
                List {
                    ForEach(filteredLogs) { log in
                        NavigationLink(destination: ConsoleLogDetailView(log: log)) {
                            ConsoleLogRowView(log: log)
                        }
                        .listRowBackground(InspectorTheme.Colors.surface)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.removeLogEntry(log.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                UIPasteboard.general.string = log.message
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .tint(InspectorTheme.Colors.accent)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .contentMargins(.vertical, InspectorTheme.Spacing.sm)
            }
        }
        .inspectorBackground()
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                chipBar
                Divider()
            }
        }
        .searchable(text: $searchText, prompt: "Message, file, type...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    copyAllLogs()
                } label: {
                    Image(systemName: showCopiedAll ? "checkmark" : "doc.on.doc")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(
                            showCopiedAll
                                ? InspectorTheme.Colors.success
                                : InspectorTheme.Colors.textSecondary
                        )
                }
            }
        }
    }

    // MARK: - Chip Bar

    private var chipBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: InspectorTheme.Spacing.sm) {
                ForEach(LogType.allCases, id: \.self) { type in
                    let count = typeCounts[type] ?? 0
                    if count > 0 {
                        FilterChipView(
                            title: type.rawValue,
                            count: count,
                            icon: type.systemImage,
                            color: type.color,
                            isSelected: selectedLogType == type
                        ) {
                            selectedLogType = selectedLogType == type ? nil : type
                        }
                    }
                }
            }
            .padding(.horizontal, InspectorTheme.Spacing.lg)
            .padding(.vertical, InspectorTheme.Spacing.sm)
        }
        .background(InspectorTheme.Colors.background)
    }

    // MARK: - Copy All Logs

    private func copyAllLogs() {
        let text = filteredLogs.map { log in
            var line = "[\(log.type.rawValue.uppercased())] \(log.message)"
            if let location = log.location {
                line += "  (\(location))"
            }
            return line
        }.joined(separator: "\n")

        UIPasteboard.general.string = text
        showCopiedAll = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            showCopiedAll = false
        }
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
