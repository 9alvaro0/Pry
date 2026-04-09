import SwiftUI

// MARK: - Reusable ViewModifiers

/// Code block container styling.
@_spi(PryPro) public struct PryCodeBlockModifier: ViewModifier {
    @_spi(PryPro) public func body(content: Content) -> some View {
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
@_spi(PryPro) public struct PryStatusBadgeModifier: ViewModifier {
    @_spi(PryPro) public let statusCode: Int

    @_spi(PryPro) public func body(content: Content) -> some View {
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

    @_spi(PryPro) public func pryCodeBlock() -> some View {
        modifier(PryCodeBlockModifier())
    }

    @_spi(PryPro) public func pryStatusBadge(_ statusCode: Int) -> some View {
        modifier(PryStatusBadgeModifier(statusCode: statusCode))
    }

    /// Applies the dark inspector background to a root view.
    @_spi(PryPro) public func pryBackground() -> some View {
        self
            .background(PryTheme.Colors.background)
            .preferredColorScheme(.dark)
    }
}
