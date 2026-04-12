import SwiftUI
import UIKit

@_spi(PryPro) public struct ConsoleMonitorView: View {
    @Bindable @_spi(PryPro) public var store: PryStore

    @_spi(PryPro) public init(store: PryStore) {
        self.store = store
    }

    @State private var selectedLogType: LogType?
    @State private var searchText: String = ""
    @State private var showCopiedAll = false
    @State private var showFilterSheet = false
    @State private var expandedLogID: UUID?
    @State private var showClearAlert = false

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

        return logs.sorted { $0.timestamp > $1.timestamp }
    }

    private var typeCounts: [LogType: Int] {
        var counts: [LogType: Int] = [:]
        for log in store.logEntries {
            counts[log.type, default: 0] += 1
        }
        return counts
    }

    private var errorCount: Int { typeCounts[.error] ?? 0 }
    private var warningCount: Int { typeCounts[.warning] ?? 0 }

    @_spi(PryPro) public var body: some View {
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
                        logRow(log)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .listRowBackground(PryTheme.Colors.background)
                            .listRowSeparatorTint(PryTheme.Colors.border.opacity(0.5))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .pryBackground()
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                summaryBar
                Divider().overlay(PryTheme.Colors.border)
            }
        }
        .searchable(text: $searchText, prompt: "Message, file, type...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { copyAllLogs() } label: {
                    Image(systemName: showCopiedAll ? "checkmark" : "doc.on.doc")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(showCopiedAll ? PryTheme.Colors.success : PryTheme.Colors.textSecondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showClearAlert = true } label: {
                    Image(systemName: "trash")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.textSecondary)
                }
                .disabled(store.logEntries.isEmpty)
                .alert("Clear Console?", isPresented: $showClearAlert) {
                    Button("Clear", role: .destructive) { store.clearLogs() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will remove all console logs.")
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            consoleFilterSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .prySheetStyle()
        }
    }

    // MARK: - Log Row (tap to expand inline)

    private func logRow(_ log: LogEntry) -> some View {
        let isExpanded = expandedLogID == log.id

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                expandedLogID = isExpanded ? nil : log.id
            } label: {
                ConsoleLogRowView(log: log)
                    .padding(.horizontal, PryTheme.Spacing.lg)
            }
            .buttonStyle(.plain)

            if isExpanded {
                expandedDetail(log)
                    .padding(.horizontal, PryTheme.Spacing.lg)
                    .padding(.bottom, PryTheme.Spacing.sm)
            }
        }
    }

    private func expandedDetail(_ log: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
            if let location = log.location {
                Text(location)
                    .font(PryTheme.Typography.codeSmall)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }

            // Actions
            HStack(spacing: PryTheme.Spacing.md) {
                Button {
                    UIPasteboard.general.string = log.message
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.accent)
                }

                Spacer()

            }
        }
        .padding(.leading, 68) // align with message text
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack(spacing: PryTheme.Spacing.md) {
            Text("\(store.logEntries.count) logs")
                .font(PryTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(PryTheme.Colors.textPrimary)

            if errorCount > 0 {
                statusDot(count: errorCount, color: PryTheme.Colors.error)
            }
            if warningCount > 0 {
                statusDot(count: warningCount, color: PryTheme.Colors.warning)
            }

            Spacer()

            if let filter = selectedLogType {
                Text(filter.rawValue)
                    .font(PryTheme.Typography.detail)
                    .fontWeight(.semibold)
                    .foregroundStyle(filter.color)
                    .padding(.horizontal, PryTheme.Spacing.pip)
                    .padding(.vertical, PryTheme.Spacing.xxs)
                    .background(filter.color.opacity(PryTheme.Opacity.badge))
                    .clipShape(.capsule)
            }

            Button { showFilterSheet = true } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(selectedLogType != nil ? PryTheme.Colors.accent : PryTheme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, PryTheme.Spacing.lg)
        .padding(.vertical, PryTheme.Spacing.sm)
        .background(PryTheme.Colors.background)
    }

    private func statusDot(count: Int, color: Color) -> some View {
        HStack(spacing: PryTheme.Spacing.xxs) {
            Circle().fill(color)
                .frame(width: PryTheme.Size.statusDot, height: PryTheme.Size.statusDot)
            Text("\(count)")
                .font(PryTheme.Typography.detail)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }

    // MARK: - Filter Sheet

    private var consoleFilterSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PryTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("TYPE")
                        .font(PryTheme.Typography.sectionLabel)
                        .tracking(PryTheme.Text.tracking)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                        .padding(.bottom, PryTheme.Spacing.sm)

                    VStack(spacing: 0) {
                        ForEach(LogType.allCases, id: \.self) { type in
                            if type != LogType.allCases.first {
                                Divider().overlay(PryTheme.Colors.border)
                            }
                            Button {
                                selectedLogType = selectedLogType == type ? nil : type
                            } label: {
                                HStack(spacing: PryTheme.Spacing.md) {
                                    Circle().fill(type.color)
                                        .frame(width: PryTheme.Size.statusDot, height: PryTheme.Size.statusDot)

                                    Text(type.rawValue)
                                        .font(PryTheme.Typography.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(PryTheme.Colors.textPrimary)

                                    Spacer()

                                    Text("\(typeCounts[type] ?? 0)")
                                        .font(PryTheme.Typography.code)
                                        .foregroundStyle(PryTheme.Colors.textTertiary)

                                    if selectedLogType == type {
                                        Image(systemName: "checkmark")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(PryTheme.Colors.accent)
                                    }
                                }
                                .padding(.horizontal, PryTheme.Spacing.md)
                                .frame(minHeight: 44)
                                .contentShape(.rect)
                            }
                        }
                    }
                    .background(PryTheme.Colors.surface)
                    .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                }

                Button { showFilterSheet = false } label: {
                    Text("Done")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(PryTheme.Colors.accent)
                        .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                }

                if selectedLogType != nil {
                    Button { selectedLogType = nil } label: {
                        Text("Reset")
                            .font(.body.weight(.medium))
                            .foregroundStyle(PryTheme.Colors.error)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(PryTheme.Colors.error.opacity(PryTheme.Opacity.badge))
                            .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                    }
                }
            }
            .padding(.horizontal, PryTheme.Spacing.lg)
            .padding(.top, PryTheme.Spacing.xl)
            .padding(.bottom, PryTheme.Spacing.xxl)
        }
        .contentMargins(.vertical, PryTheme.Spacing.sm)
        .pryBackground()
    }

    // MARK: - Copy All

    private func copyAllLogs() {
        let logs = filteredLogs
        Task.detached(priority: .userInitiated) {
            let text = logs.map { log in
                var line = "[\(log.type.rawValue.uppercased())] \(log.message)"
                if let location = log.location { line += "  (\(location))" }
                return line
            }.joined(separator: "\n")

            await MainActor.run {
                UIPasteboard.general.string = text
                showCopiedAll = true
            }
            try? await Task.sleep(for: PryTheme.Animation.toastDismiss)
            await MainActor.run { showCopiedAll = false }
        }
    }
}

#if DEBUG
#Preview("Console - With Logs") {
    NavigationStack {
        ConsoleMonitorView(store: .consoleOnly)
            .navigationTitle("Console")
    }
}

#Preview("Console - Empty") {
    NavigationStack {
        ConsoleMonitorView(store: PryStore())
            .navigationTitle("Console")
    }
}
#endif
