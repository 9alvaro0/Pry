import SwiftUI

/// Standardized sheet header with title and optional leading/trailing actions.
struct SheetHeader: View {
    let title: String
    var leadingAction: HeaderAction?
    var trailingAction: HeaderAction

    struct HeaderAction {
        let icon: String
        let color: Color
        let action: () -> Void

        static func close(_ action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(icon: "xmark", color: PryTheme.Colors.textSecondary, action: action)
        }

        static func done(_ action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(icon: "checkmark", color: PryTheme.Colors.accent, action: action)
        }

        static func reset(_ action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(icon: "arrow.counterclockwise", color: PryTheme.Colors.error, action: action)
        }
    }

    var body: some View {
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
