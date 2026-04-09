import SwiftUI

/// Wraps content behind a feature gate. Shows upgrade prompt if locked.
struct ProGateView<Content: View>: View {
    let feature: FeatureGate.Feature
    @ViewBuilder let content: () -> Content

    var body: some View {
        if FeatureGate.isAvailable(feature) {
            content()
        } else {
            proLockedView
        }
    }

    private var proLockedView: some View {
        VStack(spacing: PryTheme.Spacing.md) {
            Image(systemName: "lock.fill")
                .font(.system(size: PryTheme.FontSize.emptyState))
                .foregroundStyle(PryTheme.Colors.accent)

            Text("Pro Feature")
                .font(PryTheme.Typography.subheading)
                .foregroundStyle(PryTheme.Colors.textPrimary)

            Text(feature.displayName)
                .font(PryTheme.Typography.body)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PryTheme.Spacing.xxl)
    }
}

/// Modifier that disables a menu item and appends "Pro" label if locked.
struct ProGateModifier: ViewModifier {
    let feature: FeatureGate.Feature

    func body(content: Content) -> some View {
        if FeatureGate.isAvailable(feature) {
            content
        } else {
            content
                .disabled(true)
                .overlay(alignment: .trailing) {
                    Text("PRO")
                        .font(PryTheme.Typography.badgeText)
                        .foregroundStyle(PryTheme.Colors.accent)
                        .padding(.horizontal, PryTheme.Spacing.xs)
                        .padding(.vertical, PryTheme.Spacing.xxs)
                        .background(PryTheme.Colors.accent.opacity(PryTheme.Opacity.badge))
                        .clipShape(.capsule)
                        .padding(.trailing, PryTheme.Spacing.sm)
                }
        }
    }
}

extension View {
    /// Gates this view behind a Pro feature. Shows lock icon if unavailable.
    func proGated(_ feature: FeatureGate.Feature) -> some View {
        modifier(ProGateModifier(feature: feature))
    }
}

// MARK: - Feature Display Names

extension FeatureGate.Feature {
    var displayName: String {
        switch self {
        case .breakpoints: "Network Breakpoints"
        case .mockResponses: "Mock Responses"
        case .requestReplay: "Request Replay"
        case .requestDiff: "Request Comparison"
        case .sessionExport: "Session Export"
        case .shareSession: "Share Session"
        case .networkThrottle: "Network Throttle"
        case .protobufDecoder: "Protobuf Decoder"
        case .performanceMetrics: "Performance Metrics"
        }
    }
}
