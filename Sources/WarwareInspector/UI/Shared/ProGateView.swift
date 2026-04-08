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
        VStack(spacing: InspectorTheme.Spacing.md) {
            Image(systemName: "lock.fill")
                .font(.system(size: InspectorTheme.FontSize.emptyState))
                .foregroundStyle(InspectorTheme.Colors.accent)

            Text("Pro Feature")
                .font(InspectorTheme.Typography.subheading)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)

            Text(feature.displayName)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, InspectorTheme.Spacing.xxl)
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
                        .font(InspectorTheme.Typography.badgeText)
                        .foregroundStyle(InspectorTheme.Colors.accent)
                        .padding(.horizontal, InspectorTheme.Spacing.xs)
                        .padding(.vertical, InspectorTheme.Spacing.xxs)
                        .background(InspectorTheme.Colors.accent.opacity(InspectorTheme.Opacity.badge))
                        .clipShape(.capsule)
                        .padding(.trailing, InspectorTheme.Spacing.sm)
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
        case .sqliteViewer: "SQLite Viewer"
        case .performanceMetrics: "Performance Metrics"
        }
    }
}
