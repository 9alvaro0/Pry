import SwiftUI

struct NetworkMonitorView: View {
    @Bindable var store: InspectorStore

    @Environment(\.inspectorReadOnly) private var isReadOnly
    @State private var searchText: String = ""
    @State private var showFilterSheet = false
    @State private var showExportSheet = false

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
                                    .tint(InspectorTheme.Colors.warning)
                                }
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
                    showExportSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(InspectorTheme.Colors.textSecondary)
                }
                .disabled(filteredEntries.isEmpty)
            }
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
                        .overlay(alignment: .topTrailing) {
                            if activeFilterCount > 0 {
                                Text("\(activeFilterCount)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 14, minHeight: 14)
                                    .background(InspectorTheme.Colors.accent)
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
                .presentationBackground(InspectorTheme.Colors.background)
        }
        .sheet(isPresented: $showExportSheet) {
            exportSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(InspectorTheme.Colors.background)
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
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xl) {
                    // Sort
                    VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
                        sheetLabel("Sort By")

                        HStack(spacing: InspectorTheme.Spacing.sm) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Button {
                                    sortOrder = order
                                } label: {
                                    Text(order.rawValue)
                                        .font(InspectorTheme.Typography.body)
                                        .fontWeight(sortOrder == order ? .semibold : .regular)
                                        .foregroundStyle(sortOrder == order ? InspectorTheme.Colors.accent : InspectorTheme.Colors.textSecondary)
                                        .padding(.horizontal, InspectorTheme.Spacing.md)
                                        .padding(.vertical, InspectorTheme.Spacing.sm)
                                        .background(sortOrder == order ? InspectorTheme.Colors.accent.opacity(0.15) : InspectorTheme.Colors.surface)
                                        .clipShape(.capsule)
                                }
                            }
                        }
                    }

                    // Host
                    if !uniqueHosts.isEmpty {
                        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
                            sheetLabel("Host")

                            VStack(spacing: 0) {
                                ForEach(Array(uniqueHosts.enumerated()), id: \.element.host) { index, item in
                                    if index > 0 {
                                        Divider().overlay(InspectorTheme.Colors.border)
                                    }
                                    hostRow(label: item.host, count: item.count, isSelected: selectedHost == item.host) {
                                        selectedHost = selectedHost == item.host ? nil : item.host
                                    }
                                }
                            }
                            .background(InspectorTheme.Colors.surface)
                            .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                        }
                    }

                    // Stats toggle
                    HStack {
                        Text("Statistics")
                            .font(InspectorTheme.Typography.body)
                            .foregroundStyle(InspectorTheme.Colors.textPrimary)
                        Spacer()
                        Toggle("", isOn: Binding(get: { showStats }, set: { showStats = $0 }))
                            .tint(InspectorTheme.Colors.accent)
                            .labelsHidden()
                    }
                    .padding(InspectorTheme.Spacing.md)
                    .background(InspectorTheme.Colors.surface)
                    .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                }
                .padding(.horizontal, InspectorTheme.Spacing.lg)
                .padding(.top, InspectorTheme.Spacing.lg)
            }
        }
        .inspectorBackground()
    }

    private func hostRow(label: String, count: Int?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    .lineLimit(1)

                Spacer()

                if let count {
                    Text("\(count)")
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(InspectorTheme.Typography.detail)
                        .fontWeight(.semibold)
                        .foregroundStyle(InspectorTheme.Colors.accent)
                }
            }
            .padding(.horizontal, InspectorTheme.Spacing.md)
            .padding(.vertical, InspectorTheme.Spacing.md)
            .contentShape(.rect)
        }
    }

    private func sheetLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(InspectorTheme.Colors.textTertiary)
    }

    // MARK: - Export Sheet

    private var exportSheet: some View {
        VStack(spacing: 0) {
            SheetHeader(
                title: "Export",
                trailingAction: .close { showExportSheet = false }
            )

            ScrollView {
                VStack(spacing: InspectorTheme.Spacing.md) {
                    Text("\(filteredEntries.count) requests")
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                        .padding(.top, InspectorTheme.Spacing.md)

                    exportShareLink(
                        icon: "shippingbox",
                        title: "Postman Collection",
                        detail: "Import directly into Postman",
                        color: InspectorTheme.Colors.warning,
                        content: SessionExporter.postmanCollection(entries: filteredEntries)
                    )

                    exportShareLink(
                        icon: "terminal",
                        title: "cURL Commands",
                        detail: "All requests as cURL",
                        color: InspectorTheme.Colors.success,
                        content: SessionExporter.curlCollection(entries: filteredEntries)
                    )

                    exportShareLink(
                        icon: "doc.text",
                        title: "HAR Archive",
                        detail: "HTTP Archive format (Chrome DevTools)",
                        color: InspectorTheme.Colors.accent,
                        content: SessionExporter.harArchive(entries: filteredEntries)
                    )
                }
                .padding(.horizontal, InspectorTheme.Spacing.lg)
                .padding(.bottom, InspectorTheme.Spacing.xl)
            }
        }
        .inspectorBackground()
    }

    private func exportShareLink(icon: String, title: String, detail: String, color: Color, content: String) -> some View {
        ShareLink(item: content) {
            HStack(spacing: InspectorTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(InspectorTheme.Typography.body)
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.15))
                    .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))

                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                    Text(title)
                        .font(InspectorTheme.Typography.body)
                        .fontWeight(.medium)
                        .foregroundStyle(InspectorTheme.Colors.textPrimary)

                    Text(detail)
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }

                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(InspectorTheme.Typography.body)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
            .padding(InspectorTheme.Spacing.md)
            .background(InspectorTheme.Colors.surface)
            .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
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
