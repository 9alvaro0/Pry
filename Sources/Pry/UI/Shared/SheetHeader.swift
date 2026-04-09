import SwiftUI

/// Standardized sheet header with title and optional leading/trailing actions.
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
        @_spi(PryPro) public let icon: String
        @_spi(PryPro) public let color: Color
        @_spi(PryPro) public let action: () -> Void

        @_spi(PryPro) public static func close(_ action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(icon: "xmark", color: PryTheme.Colors.textSecondary, action: action)
        }

        @_spi(PryPro) public static func done(_ action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(icon: "checkmark", color: PryTheme.Colors.accent, action: action)
        }

        @_spi(PryPro) public static func reset(_ action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(icon: "arrow.counterclockwise", color: PryTheme.Colors.error, action: action)
        }
    }

    @_spi(PryPro) public var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let leading = leadingAction {
                    Button(action: leading.action) {
                        Image(systemName: leading.icon)
                            .font(PryTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(leading.color)
                    }
                    .frame(width: PryTheme.Size.iconMedium, alignment: .leading)
                } else {
                    Spacer()
                        .frame(width: PryTheme.Size.iconMedium)
                }

                Spacer()

                Text(title)
                    .font(PryTheme.Typography.subheading)
                    .foregroundStyle(PryTheme.Colors.textPrimary)

                Spacer()

                Button(action: trailingAction.action) {
                    Image(systemName: trailingAction.icon)
                        .font(PryTheme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(trailingAction.color)
                }
                .frame(width: PryTheme.Size.iconMedium, alignment: .trailing)
            }
            .padding(.horizontal, PryTheme.Spacing.lg)
            .padding(.vertical, PryTheme.Spacing.md)

            Divider().overlay(PryTheme.Colors.border)
        }
    }
}
