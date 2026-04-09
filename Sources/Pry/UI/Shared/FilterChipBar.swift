import SwiftUI

// MARK: - Chip Model

@_spi(PryPro) public struct ChipItem: Identifiable {
    @_spi(PryPro) public let id = UUID()
    @_spi(PryPro) public let title: String
    @_spi(PryPro) public let count: Int
    @_spi(PryPro) public var icon: String?
    @_spi(PryPro) public var color: Color = PryTheme.Colors.textSecondary
    @_spi(PryPro) public let isSelected: Bool
    @_spi(PryPro) public let action: () -> Void
}

// MARK: - Chip Bar

@_spi(PryPro) public struct FilterChipBarView<TrailingContent: View>: View {
    @_spi(PryPro) public let chips: [ChipItem]
    @ViewBuilder var trailing: () -> TrailingContent

    @_spi(PryPro) public var body: some View {
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
    @_spi(PryPro) public init(chips: [ChipItem]) {
        self.chips = chips
        self.trailing = { EmptyView() }
    }
}

// MARK: - Chip View

@_spi(PryPro) public struct FilterChipView: View {
    @_spi(PryPro) public let title: String
    @_spi(PryPro) public let count: Int
    @_spi(PryPro) public var icon: String?
    @_spi(PryPro) public var color: Color = PryTheme.Colors.textSecondary
    @_spi(PryPro) public let isSelected: Bool
    @_spi(PryPro) public let action: () -> Void

    @_spi(PryPro) public var body: some View {
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
