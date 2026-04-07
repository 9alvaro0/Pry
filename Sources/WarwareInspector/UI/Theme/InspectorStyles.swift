import SwiftUI

// MARK: - Reusable ViewModifiers

/// Code block container styling.
struct InspectorCodeBlockModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(InspectorTheme.Spacing.md)
            .background(InspectorTheme.Colors.background)
            .overlay(
                RoundedRectangle(cornerRadius: InspectorTheme.Radius.md)
                    .stroke(InspectorTheme.Colors.border, lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
    }
}

/// Status badge (HTTP status codes).
struct InspectorStatusBadgeModifier: ViewModifier {
    let statusCode: Int

    func body(content: Content) -> some View {
        content
            .font(InspectorTheme.Typography.codeSmall)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, InspectorTheme.Spacing.xxs)
            .background(InspectorTheme.Colors.statusBackground(statusCode))
            .foregroundStyle(InspectorTheme.Colors.statusForeground(statusCode))
            .clipShape(.capsule)
    }
}

// MARK: - View Extensions

extension View {

    func inspectorCodeBlock() -> some View {
        modifier(InspectorCodeBlockModifier())
    }

    func inspectorStatusBadge(_ statusCode: Int) -> some View {
        modifier(InspectorStatusBadgeModifier(statusCode: statusCode))
    }

    /// Applies the dark inspector background to a root view.
    func inspectorBackground() -> some View {
        self
            .background(InspectorTheme.Colors.background)
            .preferredColorScheme(.dark)
    }
}
