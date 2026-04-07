import SwiftUI

// MARK: - Chip Model

struct ChipItem: Identifiable {
    let id = UUID()
    let title: String
    let count: Int
    var icon: String?
    var color: Color = InspectorTheme.Colors.textSecondary
    let isSelected: Bool
    let action: () -> Void
}

// MARK: - Chip Bar

struct FilterChipBarView<TrailingContent: View>: View {
    let chips: [ChipItem]
    @ViewBuilder var trailing: () -> TrailingContent

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: InspectorTheme.Spacing.sm) {
                ForEach(chips) { chip in
                    FilterChipView(
                        title: chip.title,
                        count: chip.count,
                        icon: chip.icon,
                        color: chip.color,
                        isSelected: chip.isSelected,
                        action: chip.action
                    )
                }
                Spacer()
                trailing()
            }
            .padding(.horizontal, InspectorTheme.Spacing.lg)
            .padding(.vertical, InspectorTheme.Spacing.sm)
        }
        .background(InspectorTheme.Colors.background)
    }
}

extension FilterChipBarView where TrailingContent == EmptyView {
    init(chips: [ChipItem]) {
        self.chips = chips
        self.trailing = { EmptyView() }
    }
}

// MARK: - Chip View

struct FilterChipView: View {
    let title: String
    let count: Int
    var icon: String?
    var color: Color = InspectorTheme.Colors.textSecondary
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: InspectorTheme.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(InspectorTheme.Typography.detail)
                }

                Text(title)
                    .font(InspectorTheme.Typography.body)
                    .fontWeight(isSelected ? .semibold : .regular)

                if count > 0 {
                    Text("\(count)")
                        .font(InspectorTheme.Typography.detail)
                        .padding(.horizontal, InspectorTheme.Spacing.xs)
                        .padding(.vertical, InspectorTheme.Spacing.xxs)
                        .background(isSelected ? color.opacity(0.3) : InspectorTheme.Colors.textSecondary.opacity(0.2))
                        .clipShape(.capsule)
                }
            }
            .padding(.horizontal, InspectorTheme.Spacing.md)
            .padding(.vertical, InspectorTheme.Spacing.sm)
            .background(isSelected ? color.opacity(0.2) : InspectorTheme.Colors.textSecondary.opacity(0.1))
            .foregroundStyle(isSelected ? color : InspectorTheme.Colors.textSecondary)
            .clipShape(.capsule)
            .overlay(
                RoundedRectangle(cornerRadius: InspectorTheme.Spacing.lg)
                    .stroke(isSelected ? color : .clear, lineWidth: 1)
            )
        }
    }
}
