import SwiftUI

// MARK: - Reusable ViewModifiers

/// Code block container styling.
package struct PryCodeBlockModifier: ViewModifier {
    package func body(content: Content) -> some View {
        content
            .padding(PryTheme.Spacing.md)
            .background(PryTheme.Colors.background)
            .overlay(
                RoundedRectangle(cornerRadius: PryTheme.Radius.md)
                    .stroke(PryTheme.Colors.border, lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
    }
}

/// Status badge (HTTP status codes).
package struct PryStatusBadgeModifier: ViewModifier {
    package let statusCode: Int

    package func body(content: Content) -> some View {
        content
            .font(PryTheme.Typography.codeSmall)
            .fontWeight(.semibold)
            .padding(.horizontal, PryTheme.Spacing.pip)
            .padding(.vertical, PryTheme.Spacing.xxs)
            .background(PryTheme.Colors.statusBackground(statusCode))
            .foregroundStyle(PryTheme.Colors.statusForeground(statusCode))
            .clipShape(.capsule)
    }
}

// MARK: - View Extensions

extension View {

    package func pryCodeBlock() -> some View {
        modifier(PryCodeBlockModifier())
    }

    package func pryStatusBadge(_ statusCode: Int) -> some View {
        modifier(PryStatusBadgeModifier(statusCode: statusCode))
    }

    /// Applies the dark inspector background to a root view.
    package func pryBackground() -> some View {
        self
            .background(PryTheme.Colors.background)
            .preferredColorScheme(.dark)
    }
}
