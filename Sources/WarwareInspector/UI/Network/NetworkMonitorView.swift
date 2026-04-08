import SwiftUI

struct NetworkMonitorView: View {
    @Bindable var store: InspectorStore

    @State private var searchText: String = ""
    @State private var selectedFilter: NetworkFilter?
    @State private var sortOrder: SortOrder = .newest
    @State private var selectedHost: String?
    @State private var showStats = false
    @State private var showFilterSheet = false

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
            case .pinned: InspectorTheme.Colors.warning
            case .success: InspectorTheme.Colors.success
            case .error: InspectorTheme.Colors.error
            case .pending: InspectorTheme.Colors.pending
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

    private var filteredEntries: [NetworkEntry] {
        var entries = store.networkEntries

        if let host = selectedHost {
            entries = entries.filter { $0.requestURL.extractHost() == host }
        }

        if let filter = selectedFilter {
            if filter == .pinned {
                entries = entries.filter { store.isPinned($0.id) }
            } else {
                entries = entries.filter { filter.matches($0) }
            }
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
                (entry.displayError?.lowercased().contains(query) ?? false)
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
        var counts: [NetworkFilter: Int] = [.pinned: 0, .success: 0, .error: 0, .pending: 0]
        counts[.pinned] = store.pinnedRequestIDs.count
        for entry in store.networkEntries {
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

    var body: some View {
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
                            NetworkStatsView(entries: store.networkEntries)
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
                            .listRowBackground(InspectorTheme.Colors.surface)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.removeNetworkEntry(entry.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    store.togglePin(entry.id)
                                } label: {
                                    Image(systemName: store.isPinned(entry.id) ? "pin.slash" : "pin")
                                }
                                .tint(InspectorTheme.Colors.warning)
                            }
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
        .searchable(text: $searchText, prompt: "URL, method, status, host...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(
                            hasActiveFilters
                                ? InspectorTheme.Colors.accent
                                : InspectorTheme.Colors.textSecondary
                        )
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            filterSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Chip Bar (clean: only status filters + 1 filter button)

    private var chipBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: InspectorTheme.Spacing.sm) {
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
            .padding(.horizontal, InspectorTheme.Spacing.lg)
            .padding(.vertical, InspectorTheme.Spacing.sm)
        }
        .background(InspectorTheme.Colors.background)
    }

    // MARK: - Filter Sheet (sort + host + stats toggle)

    private var filterSheet: some View {
        NavigationStack {
            List {
                // Sort
                Section("Sort By") {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            HStack {
                                Label(order.rawValue, systemImage: order.icon)
                                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                                Spacer()
                                if sortOrder == order {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(InspectorTheme.Colors.accent)
                                }
                            }
                        }
                    }
                }

                // Host
                Section("Filter by Host") {
                    Button {
                        selectedHost = nil
                    } label: {
                        HStack {
                            Label("All Hosts", systemImage: "globe")
                                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                            Spacer()
                            if selectedHost == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(InspectorTheme.Colors.accent)
                            }
                        }
                    }

                    ForEach(uniqueHosts, id: \.host) { item in
                        Button {
                            selectedHost = item.host
                        } label: {
                            HStack {
                                Label(item.host, systemImage: "server.rack")
                                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                                Spacer()
                                Text("\(item.count)")
                                    .font(InspectorTheme.Typography.detail)
                                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
                                if selectedHost == item.host {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(InspectorTheme.Colors.accent)
                                }
                            }
                        }
                    }
                }

                // Stats toggle
                Section {
                    Toggle(isOn: $showStats) {
                        Label("Show Statistics", systemImage: "chart.bar")
                    }
                    .tint(InspectorTheme.Colors.accent)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilterSheet = false
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if hasActiveFilters {
                        Button("Reset") {
                            sortOrder = .newest
                            selectedHost = nil
                            showStats = false
                        }
                        .foregroundStyle(InspectorTheme.Colors.error)
                    }
                }
            }
        }
        .presentationBackground(InspectorTheme.Colors.background)
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
        NetworkMonitorView(store: InspectorStore())
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
