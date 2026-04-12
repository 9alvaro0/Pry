import SwiftUI

// MARK: - Reusable ViewModifiers

/// Code block container styling. Gold border when PryPro is active.
@_spi(PryPro) public struct PryCodeBlockModifier: ViewModifier {
    @SwiftUI.Environment(\.pryProGlow) private var glow

    @_spi(PryPro) public func body(content: Content) -> some View {
        content
            .padding(PryTheme.Spacing.md)
            .background(PryTheme.Colors.background)
            .overlay(
                RoundedRectangle(cornerRadius: PryTheme.Radius.md)
                    .stroke(glow?.opacity(0.35) ?? PryTheme.Colors.border, lineWidth: 1)
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

/// Applies the user's theme preference (system, light, or dark).
@_spi(PryPro) public struct PryColorSchemeModifier: ViewModifier {
    @SwiftUI.Environment(\.pryStore) private var store

    @_spi(PryPro) public func body(content: Content) -> some View {
        if let scheme = store.resolvedColorScheme {
            content.preferredColorScheme(scheme)
        } else {
            content
        }
    }
}

/// Adds a gold border glow when PryPro is active.
@_spi(PryPro) public struct PryGlowBorderModifier: ViewModifier {
    @SwiftUI.Environment(\.pryProGlow) private var glow
    let cornerRadius: CGFloat

    @_spi(PryPro) public func body(content: Content) -> some View {
        if let glow {
            content
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(glow.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: glow.opacity(0.15), radius: 6)
        } else {
            content
        }
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

    /// Applies the inspector background to a root view. Adapts to light/dark mode.
    @_spi(PryPro) public func pryBackground() -> some View {
        self
            .background(PryTheme.Colors.background)
            .modifier(PryColorSchemeModifier())
    }

    /// Adds a subtle gold glow border when PryPro is active. No effect in Free.
    @_spi(PryPro) public func pryGlowBorder(cornerRadius: CGFloat = PryTheme.Radius.lg) -> some View {
        modifier(PryGlowBorderModifier(cornerRadius: cornerRadius))
    }
}
