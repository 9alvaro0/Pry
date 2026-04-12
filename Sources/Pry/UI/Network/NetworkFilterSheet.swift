import SwiftUI

// MARK: - Shared Filter Types

enum NetworkSortOrder: String, CaseIterable {
    case newest = "Newest"
    case oldest = "Oldest"
    case slowest = "Slowest"
    case largest = "Largest"
}

enum NetworkStatusFilter: String, CaseIterable {
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
        case .pinned: true
        case .success: entry.isSuccess
        case .error: (!entry.isSuccess && entry.responseStatusCode != nil) || entry.responseError != nil
        case .pending: entry.responseStatusCode == nil && entry.responseError == nil
        }
    }
}

// MARK: - Filter Sheet

struct NetworkFilterSheet: View {
    @Binding var selectedFilter: NetworkStatusFilter?
    @Binding var sortOrder: NetworkSortOrder
    @Binding var selectedHost: String?
    @Binding var showStats: Bool
    @Binding var isPresented: Bool

    let filterCounts: [NetworkStatusFilter: Int]
    let uniqueHosts: [(host: String, count: Int)]

    private var hasActiveFilters: Bool {
        sortOrder != .newest || selectedHost != nil || showStats || selectedFilter != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PryTheme.Spacing.xl) {
                statusSection
                sortSection
                hostSection
                statsToggle
                actionButtons
            }
            .padding(.horizontal, PryTheme.Spacing.lg)
            .padding(.top, PryTheme.Spacing.xl)
            .padding(.bottom, PryTheme.Spacing.xxl)
        }
        .contentMargins(.vertical, PryTheme.Spacing.sm)
        .pryBackground()
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("STATUS")

            VStack(spacing: 0) {
                ForEach(NetworkStatusFilter.allCases, id: \.self) { filter in
                    if filter != NetworkStatusFilter.allCases.first {
                        Divider().overlay(PryTheme.Colors.border)
                    }
                    Button {
                        selectedFilter = selectedFilter == filter ? nil : filter
                    } label: {
                        HStack(spacing: PryTheme.Spacing.md) {
                            Circle()
                                .fill(filter.color)
                                .frame(width: PryTheme.Size.statusDot, height: PryTheme.Size.statusDot)

                            Text(filter.rawValue)
                                .font(PryTheme.Typography.body)
                                .fontWeight(.medium)
                                .foregroundStyle(PryTheme.Colors.textPrimary)

                            Spacer()

                            Text("\(filterCounts[filter] ?? 0)")
                                .font(PryTheme.Typography.code)
                                .foregroundStyle(PryTheme.Colors.textTertiary)

                            if selectedFilter == filter {
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
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: PryTheme.Spacing.md) {
            Button {
                isPresented = false
            } label: {
                Text("Done")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(PryTheme.Colors.accent)
                    .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
            }

            if hasActiveFilters {
                Button {
                    sortOrder = .newest
                    selectedHost = nil
                    showStats = false
                    selectedFilter = nil
                } label: {
                    Text("Reset All")
                        .font(.body.weight(.medium))
                        .foregroundStyle(PryTheme.Colors.error)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(PryTheme.Colors.error.opacity(PryTheme.Opacity.badge))
                        .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                }
            }
        }
    }

    // MARK: - Sort

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("SORT")

            VStack(spacing: 0) {
                ForEach(NetworkSortOrder.allCases, id: \.self) { order in
                    if order != NetworkSortOrder.allCases.first {
                        Divider().overlay(PryTheme.Colors.border)
                    }
                    Button {
                        sortOrder = order
                    } label: {
                        HStack {
                            Text(order.rawValue)
                                .font(PryTheme.Typography.body)
                                .fontWeight(.medium)
                                .foregroundStyle(PryTheme.Colors.textPrimary)

                            Spacer()

                            if sortOrder == order {
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
    }

    // MARK: - Host

    @ViewBuilder
    private var hostSection: some View {
        if !uniqueHosts.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel("HOST")

                VStack(spacing: 0) {
                    ForEach(Array(uniqueHosts.enumerated()), id: \.element.host) { index, item in
                        if index > 0 {
                            Divider().overlay(PryTheme.Colors.border)
                        }
                        Button {
                            selectedHost = selectedHost == item.host ? nil : item.host
                        } label: {
                            HStack {
                                Text(item.host)
                                    .font(PryTheme.Typography.code)
                                    .foregroundStyle(PryTheme.Colors.textPrimary)
                                    .lineLimit(1)

                                Spacer()

                                Text("\(item.count)")
                                    .font(PryTheme.Typography.detail)
                                    .foregroundStyle(PryTheme.Colors.textTertiary)

                                if selectedHost == item.host {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(PryTheme.Colors.accent)
                                }
                            }
                            .padding(.horizontal, PryTheme.Spacing.md)
                            .padding(.vertical, PryTheme.Spacing.md)
                            .contentShape(.rect)
                        }
                    }
                }
                .background(PryTheme.Colors.surface)
                .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
            }
        }
    }

    // MARK: - Stats

    private var statsToggle: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Show Statistics")
                    .font(PryTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(PryTheme.Colors.textPrimary)
                Spacer()
                Toggle("", isOn: $showStats)
                    .tint(PryTheme.Colors.accent)
                    .labelsHidden()
            }
            .padding(.horizontal, PryTheme.Spacing.md)
            .frame(minHeight: 44)
        }
        .background(PryTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(PryTheme.Typography.sectionLabel)
            .tracking(PryTheme.Text.tracking)
            .foregroundStyle(PryTheme.Colors.textTertiary)
            .padding(.bottom, PryTheme.Spacing.sm)
    }
}
