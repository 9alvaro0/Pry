import SwiftUI

@_spi(PryPro) public struct NetworkMonitorView: View {
    @Bindable @_spi(PryPro) public var store: PryStore

    @_spi(PryPro) public init(store: PryStore) {
        self.store = store
    }

    @Environment(\.pryReadOnly) private var isReadOnly
    @Environment(\.pryAccentOverride) private var accentOverride
    @State private var searchText: String = ""
    @State private var showFilterSheet = false

    private var resolvedAccent: Color { accentOverride ?? PryTheme.Colors.accent }

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

    private enum SortOrder: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case slowest = "Slowest"
        case largest = "Largest"

        var icon: String {
            switch self {
            case .newest: "clock.arrow.circlepath"
            case .oldest: "clock"
            case .slowest: "tortoise"
            case .largest: "arrow.up.circle"
            }
        }
    }

    private enum NetworkFilter: String, CaseIterable {
        case pinned = "Pinned"
        case success = "Success"
        case error = "Errors"
        case pending = "Pending"

        var color: Color {
            switch self {
            case .pinned: PryTheme.Colors.warning
            case .success: PryTheme.Colors.success
            case .error: PryTheme.Colors.error
            case .pending: PryTheme.Colors.pending
            }
        }

        func matches(_ entry: NetworkEntry) -> Bool {
            switch self {
            case .pinned: true // Handled separately
            case .success: entry.isSuccess
            case .error: (!entry.isSuccess && entry.responseStatusCode != nil) || entry.responseError != nil
            case .pending: entry.responseStatusCode == nil && entry.responseError == nil
            }
        }
    }

    // MARK: - Computed

    private var uniqueHosts: [(host: String, count: Int)] {
        var hostCounts: [String: Int] = [:]
        for entry in store.networkEntries {
            hostCounts[entry.requestURL.extractHost(), default: 0] += 1
        }
        return hostCounts.sorted { $0.key < $1.key }.map { (host: $0.key, count: $0.value) }
    }

    private var hasActiveFilters: Bool {
        sortOrder != .newest || selectedHost != nil || showStats
    }

    private var activeFilterCount: Int {
        var count = 0
        if sortOrder != .newest { count += 1 }
        if selectedHost != nil { count += 1 }
        if showStats { count += 1 }
        return count
    }

    /// Entries filtered by host + search but NOT by chip filter.
    /// Used as the base for both the final list and chip counts.
    private var baseFilteredEntries: [NetworkEntry] {
        var entries = store.networkEntries

        if let host = selectedHost {
            entries = entries.filter { $0.requestURL.extractHost() == host }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            entries = entries.filter { entry in
                entry.requestMethod.lowercased().contains(query) ||
                entry.requestURL.extractPath().lowercased().contains(query) ||
                entry.requestURL.extractHost().lowercased().contains(query) ||
                (entry.responseStatusCode.map { String($0).contains(query) } ?? false) ||
                (entry.responseStatusCode.map { HTTPStatus.description(for: $0).lowercased().contains(query) } ?? false) ||
                (entry.responseError?.lowercased().contains(query) ?? false) ||
                (entry.displayError?.lowercased().contains(query) ?? false) ||
                (entry.graphQLInfo?.operationName?.lowercased().contains(query) ?? false)
            }
        }

        return entries
    }

    private var filteredEntries: [NetworkEntry] {
        var entries = baseFilteredEntries

        if let filter = selectedFilter {
            if filter == .pinned {
                entries = entries.filter { store.isPinned($0.id) }
            } else {
                entries = entries.filter { filter.matches($0) }
            }
        }

        switch sortOrder {
        case .newest: entries.sort { $0.timestamp > $1.timestamp }
        case .oldest: entries.sort { $0.timestamp < $1.timestamp }
        case .slowest: entries.sort { ($0.duration ?? 0) > ($1.duration ?? 0) }
        case .largest: entries.sort { ($0.responseSize ?? 0) > ($1.responseSize ?? 0) }
        }

        return entries
    }

    private var filterCounts: [NetworkFilter: Int] {
        let entries = baseFilteredEntries
        var counts: [NetworkFilter: Int] = [.pinned: 0, .success: 0, .error: 0, .pending: 0]
        counts[.pinned] = entries.filter { store.isPinned($0.id) }.count
        for entry in entries {
            if entry.isSuccess {
                counts[.success, default: 0] += 1
            } else if entry.responseStatusCode == nil && entry.responseError == nil {
                counts[.pending, default: 0] += 1
            } else {
                counts[.error, default: 0] += 1
            }
        }
        return counts
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
                    // Stats as first list section
                    if showStats {
                        Section {
                            NetworkStatsView(entries: baseFilteredEntries)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }
                    }

                    // Requests
                    Section {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(destination: NetworkRequestDetailView(entry: entry)) {
                                NetworkRequestRowView(entry: entry, isPinned: store.isPinned(entry.id))
                            }
                            .listRowBackground(PryTheme.Colors.surface)
                            .swipeActions(edge: .trailing, allowsFullSwipe: !isReadOnly) {
                                if !isReadOnly {
                                    Button(role: .destructive) {
                                        store.removeNetworkEntry(entry.id)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: !isReadOnly) {
                                if !isReadOnly {
                                    Button {
                                        store.togglePin(entry.id)
                                    } label: {
                                        Image(systemName: store.isPinned(entry.id) ? "pin.slash" : "pin")
                                    }
                                    .tint(PryTheme.Colors.warning)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .contentMargins(.vertical, PryTheme.Spacing.sm)
            }
        }
        .pryBackground()
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                chipBar
                Divider()
            }
        }
        .searchable(text: $searchText, prompt: "URL, method, status, host...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(
                            hasActiveFilters
                                ? resolvedAccent
                                : PryTheme.Colors.textSecondary
                        )
                        .overlay(alignment: .topTrailing) {
                            if activeFilterCount > 0 {
                                Text("\(activeFilterCount)")
                                    .font(PryTheme.Typography.badgeText)
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 14, minHeight: 14)
                                    .background(resolvedAccent)
                                    .clipShape(.circle)
                                    .offset(x: 8, y: -8)
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            filterSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(PryTheme.Colors.background)
        }
    }

    // MARK: - Chip Bar (clean: only status filters + 1 filter button)

    private var chipBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PryTheme.Spacing.sm) {
                ForEach(NetworkFilter.allCases, id: \.self) { filter in
                    FilterChipView(
                        title: filter == .pinned ? "" : filter.rawValue,
                        count: filterCounts[filter] ?? 0,
                        icon: filter == .pinned ? "pin.fill" : nil,
                        color: filter.color,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = selectedFilter == filter ? nil : filter
                    }
                }
            }
            .padding(.horizontal, PryTheme.Spacing.lg)
            .padding(.vertical, PryTheme.Spacing.sm)
        }
        .background(PryTheme.Colors.background)
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        VStack(spacing: 0) {
            SheetHeader(
                title: "Filters",
                leadingAction: hasActiveFilters ? .reset {
                    sortOrder = .newest
                    selectedHost = nil
                    showStats = false
                } : nil,
                trailingAction: .done { showFilterSheet = false }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.xl) {
                    // Sort
                    VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                        sheetLabel("Sort By")

                        HStack(spacing: PryTheme.Spacing.sm) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Button {
                                    sortOrder = order
                                } label: {
                                    Text(order.rawValue)
                                        .font(PryTheme.Typography.body)
                                        .fontWeight(sortOrder == order ? .semibold : .regular)
                                        .foregroundStyle(sortOrder == order ? resolvedAccent : PryTheme.Colors.textSecondary)
                                        .padding(.horizontal, PryTheme.Spacing.md)
                                        .padding(.vertical, PryTheme.Spacing.sm)
                                        .background(sortOrder == order ? resolvedAccent.opacity(PryTheme.Opacity.badge) : PryTheme.Colors.surface)
                                        .clipShape(.capsule)
                                }
                            }
                        }
                    }

                    // Host
                    if !uniqueHosts.isEmpty {
                        VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                            sheetLabel("Host")

                            VStack(spacing: 0) {
                                ForEach(Array(uniqueHosts.enumerated()), id: \.element.host) { index, item in
                                    if index > 0 {
                                        Divider().overlay(PryTheme.Colors.border)
                                    }
                                    hostRow(label: item.host, count: item.count, isSelected: selectedHost == item.host) {
                                        selectedHost = selectedHost == item.host ? nil : item.host
                                    }
                                }
                            }
                            .background(PryTheme.Colors.surface)
                            .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                        }
                    }

                    // Stats toggle
                    HStack {
                        Text("Statistics")
                            .font(PryTheme.Typography.body)
                            .foregroundStyle(PryTheme.Colors.textPrimary)
                        Spacer()
                        Toggle("", isOn: Binding(get: { showStats }, set: { showStats = $0 }))
                            .tint(resolvedAccent)
                            .labelsHidden()
                    }
                    .padding(PryTheme.Spacing.md)
                    .background(PryTheme.Colors.surface)
                    .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                }
                .padding(.horizontal, PryTheme.Spacing.lg)
                .padding(.top, PryTheme.Spacing.lg)
            }
        }
        .pryBackground()
    }

    private func hostRow(label: String, count: Int?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textPrimary)
                    .lineLimit(1)

                Spacer()

                if let count {
                    Text("\(count)")
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(PryTheme.Typography.detail)
                        .fontWeight(.semibold)
                        .foregroundStyle(resolvedAccent)
                }
            }
            .padding(.horizontal, PryTheme.Spacing.md)
            .padding(.vertical, PryTheme.Spacing.md)
            .contentShape(.rect)
        }
    }

    private func sheetLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(PryTheme.Typography.sectionLabel)
            .tracking(PryTheme.Text.tracking)
            .foregroundStyle(PryTheme.Colors.textTertiary)
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
