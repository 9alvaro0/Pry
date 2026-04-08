import SwiftUI

struct NetworkMonitorView: View {
    @Bindable var store: InspectorStore

    @State private var searchText: String = ""
    @State private var selectedFilter: NetworkFilter = .all
    @State private var sortOrder: SortOrder = .newest
    @State private var selectedHost: String?

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
        case all = "All"
        case success = "Success"
        case error = "Errors"
        case pending = "Pending"

        var color: Color {
            switch self {
            case .all: InspectorTheme.Colors.textSecondary
            case .success: InspectorTheme.Colors.success
            case .error: InspectorTheme.Colors.error
            case .pending: InspectorTheme.Colors.pending
            }
        }

        func matches(_ entry: NetworkEntry) -> Bool {
            switch self {
            case .all: true
            case .success: entry.isSuccess
            case .error: (!entry.isSuccess && entry.responseStatusCode != nil) || entry.responseError != nil
            case .pending: entry.responseStatusCode == nil && entry.responseError == nil
            }
        }
    }

    private var uniqueHosts: [(host: String, count: Int)] {
        var hostCounts: [String: Int] = [:]
        for entry in store.networkEntries {
            let host = entry.requestURL.extractHost()
            hostCounts[host, default: 0] += 1
        }
        return hostCounts.sorted { $0.key < $1.key }.map { (host: $0.key, count: $0.value) }
    }

    private var filteredEntries: [NetworkEntry] {
        var entries = store.networkEntries

        if let host = selectedHost {
            entries = entries.filter { $0.requestURL.extractHost() == host }
        }

        if selectedFilter != .all {
            entries = entries.filter { selectedFilter.matches($0) }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            entries = entries.filter { entry in
                // Method: "get", "post", "delete"...
                entry.requestMethod.lowercased().contains(query) ||
                // URL path: "/v1/users", "/health"...
                entry.requestURL.extractPath().lowercased().contains(query) ||
                // Host: "api.example.com"
                entry.requestURL.extractHost().lowercased().contains(query) ||
                // Status code: "404", "200", "500"
                (entry.responseStatusCode.map { String($0).contains(query) } ?? false) ||
                // Status description: "not found", "ok", "internal server"
                (entry.responseStatusCode.map { HTTPStatus.description(for: $0).lowercased().contains(query) } ?? false) ||
                // Error message
                (entry.responseError?.lowercased().contains(query) ?? false) ||
                // Display error (extracted from JSON)
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
        var counts: [NetworkFilter: Int] = [.all: 0, .success: 0, .error: 0, .pending: 0]
        for entry in store.networkEntries {
            counts[.all, default: 0] += 1
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
                    ForEach(filteredEntries) { entry in
                        NavigationLink(destination: NetworkRequestDetailView(entry: entry)) {
                            NetworkRequestRowView(entry: entry)
                        }
                        .listRowBackground(InspectorTheme.Colors.surface)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .contentMargins(.top, InspectorTheme.Spacing.sm)
            }
        }
        .inspectorBackground()
        .safeAreaInset(edge: .top, spacing: 0) {
            toolbarArea
        }
        .searchable(text: $searchText, prompt: "URL, method, status, host...")
    }

    // MARK: - Toolbar Area (Chips + Sort)

    private var toolbarArea: some View {
        HStack(spacing: 0) {
            // Scrollable chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: InspectorTheme.Spacing.sm) {
                    ForEach(NetworkFilter.allCases, id: \.self) { filter in
                        FilterChipView(
                            title: filter.rawValue,
                            count: filterCounts[filter] ?? 0,
                            color: filter.color,
                            isSelected: selectedFilter == filter
                        ) { selectedFilter = filter }
                    }
                }
                .padding(.horizontal, InspectorTheme.Spacing.lg)
                .padding(.vertical, InspectorTheme.Spacing.sm)
            }

            // Sort button (always visible, outside scroll)
            Divider()
                .frame(height: 20)

            sortButton
                .padding(.horizontal, InspectorTheme.Spacing.md)

            Divider()
                .frame(height: 20)

            hostFilterButton
                .padding(.horizontal, InspectorTheme.Spacing.md)
        }
        .background(InspectorTheme.Colors.background)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var sortButton: some View {
        Menu {
            ForEach(SortOrder.allCases, id: \.self) { order in
                Button {
                    withAnimation { sortOrder = order }
                } label: {
                    Label(order.rawValue, systemImage: sortOrder == order ? "checkmark" : order.icon)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(InspectorTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(
                    sortOrder != .newest
                        ? InspectorTheme.Colors.accent
                        : InspectorTheme.Colors.textSecondary
                )
        }
    }

    private var hostFilterButton: some View {
        Menu {
            Button {
                withAnimation { selectedHost = nil }
            } label: {
                Label("All Hosts", systemImage: selectedHost == nil ? "checkmark" : "globe")
            }

            ForEach(uniqueHosts, id: \.host) { item in
                Button {
                    withAnimation { selectedHost = item.host }
                } label: {
                    Label(
                        "\(item.host) (\(item.count))",
                        systemImage: selectedHost == item.host ? "checkmark" : "server.rack"
                    )
                }
            }
        } label: {
            Image(systemName: "server.rack")
                .font(InspectorTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(
                    selectedHost != nil
                        ? InspectorTheme.Colors.accent
                        : InspectorTheme.Colors.textSecondary
                )
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
#endif
