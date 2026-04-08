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
            HeaderAction(icon: "xmark", color: InspectorTheme.Colors.textSecondary, action: action)
        }

        static func done(_ action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(icon: "checkmark", color: InspectorTheme.Colors.accent, action: action)
        }

        static func reset(_ action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(icon: "arrow.counterclockwise", color: InspectorTheme.Colors.error, action: action)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let leading = leadingAction {
                    Button(action: leading.action) {
                        Image(systemName: leading.icon)
                            .font(InspectorTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(leading.color)
                    }
                    .frame(width: InspectorTheme.Size.iconMedium, alignment: .leading)
                } else {
                    Spacer()
                        .frame(width: InspectorTheme.Size.iconMedium)
                }

                Spacer()

                Text(title)
                    .font(InspectorTheme.Typography.subheading)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)

                Spacer()

                Button(action: trailingAction.action) {
                    Image(systemName: trailingAction.icon)
                        .font(InspectorTheme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(trailingAction.color)
                }
                .frame(width: InspectorTheme.Size.iconMedium, alignment: .trailing)
            }
            .padding(.horizontal, InspectorTheme.Spacing.lg)
            .padding(.vertical, InspectorTheme.Spacing.md)

            Divider().overlay(InspectorTheme.Colors.border)
        }
    }
}
