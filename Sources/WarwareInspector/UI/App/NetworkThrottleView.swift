import SwiftUI

/// Dedicated view for selecting network condition presets.
struct NetworkThrottleView: View {
    @Bindable var store: InspectorStore

    var body: some View {
        List {
            Section {
                ForEach(NetworkThrottle.allCases, id: \.self) { preset in
                    Button {
                        store.networkThrottle = preset
                    } label: {
                        HStack(spacing: InspectorTheme.Spacing.md) {
                            Image(systemName: preset.icon)
                                .font(InspectorTheme.Typography.body)
                                .foregroundStyle(preset.iconColor)
                                .frame(width: InspectorTheme.Size.iconMedium, height: InspectorTheme.Size.iconMedium)
                                .background(preset.iconColor.opacity(InspectorTheme.Opacity.badge))
                                .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))

                            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                                Text(preset.rawValue)
                                    .font(InspectorTheme.Typography.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                                Text(preset.description)
                                    .font(InspectorTheme.Typography.detail)
                                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
                            }

                            Spacer()

                            if store.networkThrottle == preset {
                                Image(systemName: "checkmark")
                                    .font(InspectorTheme.Typography.detail)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(InspectorTheme.Colors.accent)
                            }
                        }
                    }
                }
            } footer: {
                Text("Simulates network latency and failures. Applies to all intercepted requests in real time.")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
            .listRowBackground(InspectorTheme.Colors.surface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .inspectorBackground()
    }
}

// MARK: - NetworkThrottle UI Helpers

extension NetworkThrottle {
    var icon: String {
        switch self {
        case .none: "bolt"
        case .slow3G: "tortoise"
        case .fast3G: "hare"
        case .lossy: "wifi.exclamationmark"
        case .offline: "wifi.slash"
        }
    }

    var iconColor: Color {
        switch self {
        case .none: InspectorTheme.Colors.success
        case .slow3G: InspectorTheme.Colors.warning
        case .fast3G: InspectorTheme.Colors.accent
        case .lossy: InspectorTheme.Colors.error
        case .offline: InspectorTheme.Colors.textTertiary
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Network Throttle") {
    NavigationStack {
        NetworkThrottleView(store: .preview)
            .navigationTitle("Network Conditions")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
