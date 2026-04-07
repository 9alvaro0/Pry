import SwiftUI

// MARK: - Reusable ViewModifiers

/// Dark surface container with border.
struct InspectorSurfaceModifier: ViewModifier {
    var radius: CGFloat = InspectorTheme.Radius.md

    func body(content: Content) -> some View {
        content
            .padding(InspectorTheme.Spacing.md)
            .background(InspectorTheme.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(InspectorTheme.Colors.border, lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: radius))
    }
}

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

/// HTTP method badge.
struct InspectorMethodBadgeModifier: ViewModifier {
    let method: String

    func body(content: Content) -> some View {
        let color = InspectorTheme.Colors.methodColor(method)
        content
            .font(InspectorTheme.Typography.code)
            .fontWeight(.semibold)
            .padding(.horizontal, InspectorTheme.Spacing.sm)
            .padding(.vertical, InspectorTheme.Spacing.xxs)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))
    }
}

// MARK: - View Extensions

extension View {

    func inspectorSurface(radius: CGFloat = InspectorTheme.Radius.md) -> some View {
        modifier(InspectorSurfaceModifier(radius: radius))
    }

    func inspectorCodeBlock() -> some View {
        modifier(InspectorCodeBlockModifier())
    }

    func inspectorStatusBadge(_ statusCode: Int) -> some View {
        modifier(InspectorStatusBadgeModifier(statusCode: statusCode))
    }

    func inspectorMethodBadge(_ method: String) -> some View {
        modifier(InspectorMethodBadgeModifier(method: method))
    }

    /// Applies the dark inspector background to a root view.
    func inspectorBackground() -> some View {
        self
            .background(InspectorTheme.Colors.background)
            .preferredColorScheme(.dark)
    }
}
