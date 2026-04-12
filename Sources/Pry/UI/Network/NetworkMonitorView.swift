import SwiftUI
import UIKit

@_spi(PryPro) public struct NetworkMonitorView: View {
    @Bindable @_spi(PryPro) public var store: PryStore

    @_spi(PryPro) public init(store: PryStore) {
        self.store = store
    }

    @Environment(\.pryReadOnly) private var isReadOnly
    @State private var searchText: String = ""
    @State private var showFilterSheet = false
    @State private var groupByHost = false

    private var selectedFilter: NetworkFilter? {
        get { store.networkSelectedFilter.flatMap { NetworkFilter(rawValue: $0) } }
        nonmutating set { store.networkSelectedFilter = newValue?.rawValue }
    }

    private var sortOrder: SortOrder {
        get { SortOrder.allCases.indices.contains(store.networkSortOrder) ? SortOrder.allCases[store.networkSortOrder] : .newest }
        nonmutating set { store.networkSortOrder = SortOrder.allCases.firstIndex(of: newValue) ?? 0 }
    }

    private var selectedHost: String? {
        get { store.networkSelectedHost }
        nonmutating set { store.networkSelectedHost = newValue }
    }

    private var showStats: Bool {
        get { store.networkShowStats }
        nonmutating set { store.networkShowStats = newValue }
    }

    typealias SortOrder = NetworkSortOrder
    typealias NetworkFilter = NetworkStatusFilter

    // MARK: - Computed (single-pass processing)

    private struct ProcessedEntries {
        var filtered: [NetworkEntry] = []
        var pinned: [NetworkEntry] = []
        var unpinned: [NetworkEntry] = []
        var counts: [NetworkFilter: Int] = [.success: 0, .error: 0, .pending: 0]
        var hosts: [(host: String, count: Int)] = []
        var totalBase: Int = 0
        var grouped: [(host: String, entries: [NetworkEntry])] = []
    }

    private var processed: ProcessedEntries {
        let allEntries = store.networkEntries
        let query = searchText.isEmpty ? nil : searchText.lowercased()
        var hostCounts: [String: Int] = [:]
        var baseEntries: [NetworkEntry] = []
        var counts: [NetworkFilter: Int] = [.success: 0, .error: 0, .pending: 0]

        // Single pass: host counts + base filtering + status counts
        for entry in allEntries {
            let host = entry.requestURL.extractHost()
            hostCounts[host, default: 0] += 1

            // Host filter
            if let selectedHost, host != selectedHost { continue }

            // Search filter
            if let query {
                let matches =
                    entry.requestMethod.localizedCaseInsensitiveContains(query) ||
                    entry.requestURL.extractPath().localizedCaseInsensitiveContains(query) ||
                    host.localizedCaseInsensitiveContains(query) ||
                    (entry.responseStatusCode.map { String($0).contains(query) } ?? false) ||
                    (entry.graphQLInfo?.operationName?.localizedCaseInsensitiveContains(query) ?? false)
                if !matches { continue }
            }

            // Count status
            if entry.isSuccess {
                counts[.success, default: 0] += 1
            } else if entry.responseStatusCode == nil && entry.responseError == nil {
                counts[.pending, default: 0] += 1
            } else {
                counts[.error, default: 0] += 1
            }

            baseEntries.append(entry)
        }

        // Status filter
        var filtered = baseEntries
        if let filter = selectedFilter {
            filtered = filtered.filter { filter.matches($0) }
        }

        // Sort
        switch sortOrder {
        case .newest: filtered.sort { $0.timestamp > $1.timestamp }
        case .oldest: filtered.sort { $0.timestamp < $1.timestamp }
        case .slowest: filtered.sort { ($0.duration ?? 0) > ($1.duration ?? 0) }
        case .largest: filtered.sort { ($0.responseSize ?? 0) > ($1.responseSize ?? 0) }
        }

        // Split pinned/unpinned
        var pinned: [NetworkEntry] = []
        var unpinned: [NetworkEntry] = []
        if selectedFilter == nil {
            for entry in filtered {
                if store.isPinned(entry.id) { pinned.append(entry) }
                else { unpinned.append(entry) }
            }
        } else {
            unpinned = filtered
        }

        let hosts = hostCounts.sorted { $0.key < $1.key }.map { (host: $0.key, count: $0.value) }

        // Group by host
        var hostGroups: [String: [NetworkEntry]] = [:]
        for entry in filtered {
            let host = entry.requestURL.extractHost()
            hostGroups[host, default: []].append(entry)
        }
        let grouped = hostGroups.sorted { $0.key < $1.key }.map { (host: $0.key, entries: $0.value) }

        return ProcessedEntries(
            filtered: filtered, pinned: pinned, unpinned: unpinned,
            counts: counts, hosts: hosts, totalBase: baseEntries.count,
            grouped: grouped
        )
    }

    private var hasActiveFilters: Bool {
        sortOrder != .newest || selectedHost != nil || showStats || selectedFilter != nil
    }

    // MARK: - Body

    @_spi(PryPro) public var body: some View {
        Group {
            if store.networkEntries.isEmpty {
                EmptyStateView(
                    title: "No network requests",
                    systemImage: "network",
                    description: "Network requests will appear here as you use the app"
                )
            } else {
                List {
                    if showStats {
                        Section {
                            NetworkStatsView(entries: processed.filtered)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }
                    }

                    if groupByHost {
                        // Grouped by domain
                        ForEach(processed.grouped, id: \.host) { group in
                            Section {
                                ForEach(group.entries) { entry in
                                    requestRow(entry)
                                }
                            } header: {
                                HStack {
                                    Text(group.host)
                                        .font(PryTheme.Typography.code)
                                        .foregroundStyle(PryTheme.Colors.textPrimary)
                                    Spacer()
                                    Text("\(group.entries.count)")
                                        .font(PryTheme.Typography.detail)
                                        .foregroundStyle(PryTheme.Colors.textTertiary)
                                }
                            }
                        }
                    } else {
                        // Pinned section
                        if !processed.pinned.isEmpty {
                            Section {
                                ForEach(processed.pinned) { entry in
                                    requestRow(entry)
                                }
                            } header: {
                                HStack(spacing: PryTheme.Spacing.xs) {
                                    Image(systemName: "pin.fill")
                                        .font(PryTheme.Typography.detail)
                                    Text("PINNED")
                                        .font(PryTheme.Typography.sectionLabel)
                                        .tracking(PryTheme.Text.tracking)
                                }
                                .foregroundStyle(PryTheme.Colors.warning)
                            }
                        }

                        // Main requests
                        Section {
                            ForEach(processed.unpinned) { entry in
                                requestRow(entry)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .contentMargins(.vertical, PryTheme.Spacing.sm)
                .listRowSeparatorTint(PryTheme.Colors.border)
            }
        }
        .pryBackground()
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                summaryBar
                Divider().overlay(PryTheme.Colors.border)
            }
        }
        .searchable(text: $searchText, prompt: "URL, method, status, host...")
        .sheet(isPresented: $showFilterSheet) {
            NetworkFilterSheet(
                selectedFilter: Binding(get: { selectedFilter }, set: { selectedFilter = $0 }),
                sortOrder: Binding(get: { sortOrder }, set: { sortOrder = $0 }),
                selectedHost: Binding(get: { selectedHost }, set: { selectedHost = $0 }),
                showStats: Binding(get: { showStats }, set: { showStats = $0 }),
                isPresented: $showFilterSheet,
                filterCounts: processed.counts,
                uniqueHosts: processed.hosts
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(PryTheme.Colors.background)
        }
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack(spacing: PryTheme.Spacing.md) {
            Text("\(processed.totalBase) requests")
                .font(PryTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(PryTheme.Colors.textPrimary)

            if let count = processed.counts[.error], count > 0 {
                statusDot(count: count, color: PryTheme.Colors.error)
            }

            if let count = processed.counts[.pending], count > 0 {
                statusDot(count: count, color: PryTheme.Colors.pending)
            }

            Spacer()

            if let filter = selectedFilter {
                Text(filter.rawValue)
                    .font(PryTheme.Typography.detail)
                    .fontWeight(.semibold)
                    .foregroundStyle(filter.color)
                    .padding(.horizontal, PryTheme.Spacing.pip)
                    .padding(.vertical, PryTheme.Spacing.xxs)
                    .background(filter.color.opacity(PryTheme.Opacity.badge))
                    .clipShape(.capsule)
            }

            Button { groupByHost.toggle() } label: {
                Image(systemName: groupByHost ? "list.bullet" : "square.grid.2x2")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(groupByHost ? PryTheme.Colors.accent : PryTheme.Colors.textTertiary)
            }

            Button { showFilterSheet = true } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(hasActiveFilters ? PryTheme.Colors.accent : PryTheme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, PryTheme.Spacing.lg)
        .padding(.vertical, PryTheme.Spacing.sm)
        .background(PryTheme.Colors.background)
    }

    private func statusDot(count: Int, color: Color) -> some View {
        HStack(spacing: PryTheme.Spacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: PryTheme.Size.statusDot, height: PryTheme.Size.statusDot)
            Text("\(count)")
                .font(PryTheme.Typography.detail)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }

    // MARK: - Request Row

    @ViewBuilder
    private func requestRow(_ entry: NetworkEntry) -> some View {
        NavigationLink(destination: NetworkRequestDetailView(entry: entry)) {
            NetworkRequestRowView(entry: entry, isPinned: store.isPinned(entry.id))
        }
        .listRowBackground(PryTheme.Colors.surface)
        .swipeActions(edge: .trailing, allowsFullSwipe: !isReadOnly) {
            if !isReadOnly {
                Button(role: .destructive) {
                    store.removeNetworkEntry(entry.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: !isReadOnly) {
            if !isReadOnly {
                Button {
                    store.togglePin(entry.id)
                } label: {
                    Label(
                        store.isPinned(entry.id) ? "Unpin" : "Pin",
                        systemImage: store.isPinned(entry.id) ? "pin.slash.fill" : "pin.fill"
                    )
                }
                .tint(PryTheme.Colors.warning)

                Button {
                    UIPasteboard.general.string = entry.requestURL
                } label: {
                    Label("URL", systemImage: "link")
                }
                .tint(PryTheme.Colors.info)

                Button {
                    UIPasteboard.general.string = NetworkCurlGenerator.generate(for: entry)
                } label: {
                    Label("cURL", systemImage: "terminal.fill")
                }
                .tint(PryTheme.Colors.syntaxBool)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Network - With Requests") {
    NavigationStack {
        NetworkMonitorView(store: .networkOnly)
            .navigationTitle("Network")
    }
}

#Preview("Network - Empty") {
    NavigationStack {
        NetworkMonitorView(store: PryStore())
            .navigationTitle("Network")
    }
}

#Preview("Network - Full") {
    NavigationStack {
        NetworkMonitorView(store: .preview)
            .navigationTitle("Network")
    }
}
#endif
