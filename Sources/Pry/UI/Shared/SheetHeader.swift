import SwiftUI

/// Standardized sheet header with title and pill action buttons.
@_spi(PryPro) public struct SheetHeader: View {
    @_spi(PryPro) public let title: String
    @_spi(PryPro) public var leadingAction: HeaderAction?
    @_spi(PryPro) public var trailingAction: HeaderAction

    @_spi(PryPro) public init(title: String, leadingAction: HeaderAction? = nil, trailingAction: HeaderAction) {
        self.title = title
        self.leadingAction = leadingAction
        self.trailingAction = trailingAction
    }

    @_spi(PryPro) public struct HeaderAction {
        @_spi(PryPro) public let label: String
        @_spi(PryPro) public let icon: String?
        @_spi(PryPro) public let color: Color
        @_spi(PryPro) public let style: Style

        @_spi(PryPro) public enum Style { case filled, outline }

        @_spi(PryPro) public let action: () -> Void

        @_spi(PryPro) public static func close(_ action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(label: "Close", icon: "xmark", color: PryTheme.Colors.textSecondary, style: .outline, action: action)
        }

        @_spi(PryPro) public static func done(_ action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(label: "Done", icon: "checkmark", color: PryTheme.Colors.accent, style: .filled, action: action)
        }

        @_spi(PryPro) public static func reset(_ action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(label: "Reset", icon: "arrow.counterclockwise", color: PryTheme.Colors.error, style: .outline, action: action)
        }
    }

    @_spi(PryPro) public var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let leading = leadingAction {
                    pillButton(leading)
                } else {
                    Color.clear.frame(width: 80)
                }

                Spacer()

                Text(title)
                    .font(.headline)
                    .foregroundStyle(PryTheme.Colors.textPrimary)

                Spacer()

                pillButton(trailingAction)
            }
            .padding(.horizontal, PryTheme.Spacing.lg)
            .frame(height: 56)

            Divider().overlay(PryTheme.Colors.border)
        }
    }

    private func pillButton(_ action: HeaderAction) -> some View {
        Button(action: action.action) {
            HStack(spacing: PryTheme.Spacing.xs) {
                if let icon = action.icon {
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                }
                Text(action.label)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(action.style == .filled ? .white : action.color)
            .padding(.horizontal, PryTheme.Spacing.md)
            .padding(.vertical, PryTheme.Spacing.sm)
            .background(
                action.style == .filled
                    ? AnyShapeStyle(action.color)
                    : AnyShapeStyle(action.color.opacity(PryTheme.Opacity.badge))
            )
            .clipShape(.capsule)
        }
    }
}
