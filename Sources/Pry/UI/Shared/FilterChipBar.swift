import SwiftUI

// MARK: - Chip Model

struct ChipItem: Identifiable {
    let id = UUID()
    let title: String
    let count: Int
    var icon: String?
    var color: Color = PryTheme.Colors.textSecondary
    let isSelected: Bool
    let action: () -> Void
}

// MARK: - Chip Bar

struct FilterChipBarView<TrailingContent: View>: View {
    let chips: [ChipItem]
    @ViewBuilder var trailing: () -> TrailingContent

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PryTheme.Spacing.sm) {
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
            .padding(.horizontal, PryTheme.Spacing.lg)
            .padding(.vertical, PryTheme.Spacing.sm)
        }
        .background(PryTheme.Colors.background)
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
    var color: Color = PryTheme.Colors.textSecondary
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: PryTheme.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(PryTheme.Typography.detail)
                }

                if !title.isEmpty {
                    Text(title)
                        .font(PryTheme.Typography.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                }

                if count > 0 {
                    Text("\(count)")
                        .font(PryTheme.Typography.detail)
                        .padding(.horizontal, PryTheme.Spacing.xs)
                        .padding(.vertical, PryTheme.Spacing.xxs)
                        .background(isSelected ? color.opacity(PryTheme.Opacity.moderate) : PryTheme.Colors.textSecondary.opacity(PryTheme.Opacity.medium))
                        .clipShape(.capsule)
                }
            }
            .padding(.horizontal, PryTheme.Spacing.md)
            .padding(.vertical, PryTheme.Spacing.sm)
            .background(isSelected ? color.opacity(PryTheme.Opacity.medium) : PryTheme.Colors.textSecondary.opacity(PryTheme.Opacity.border))
            .foregroundStyle(isSelected ? color : PryTheme.Colors.textSecondary)
            .clipShape(.capsule)
            .overlay(
                RoundedRectangle(cornerRadius: PryTheme.Spacing.lg)
                    .stroke(isSelected ? color : .clear, lineWidth: 1)
            )
        }
    }
}

#if DEBUG
#Preview("Filter Chips") {
    FilterChipBarView(chips: [
        ChipItem(title: "All", count: 8, isSelected: true) {},
        ChipItem(title: "Success", count: 5, color: PryTheme.Colors.success, isSelected: false) {},
        ChipItem(title: "Errors", count: 2, color: PryTheme.Colors.error, isSelected: false) {},
        ChipItem(title: "Pending", count: 1, color: PryTheme.Colors.pending, isSelected: false) {},
    ])
    .pryBackground()
}
#endif
