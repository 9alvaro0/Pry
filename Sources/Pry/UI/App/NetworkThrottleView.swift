import SwiftUI

/// Dedicated view for selecting network condition presets.
struct NetworkThrottleView: View {
    @Bindable var store: PryStore

    var body: some View {
        List {
            Section {
                ForEach(NetworkThrottle.allCases, id: \.self) { preset in
                    Button {
                        store.networkThrottle = preset
                    } label: {
                        HStack(spacing: PryTheme.Spacing.md) {
                            Image(systemName: preset.icon)
                                .font(PryTheme.Typography.body)
                                .foregroundStyle(preset.iconColor)
                                .frame(width: PryTheme.Size.iconMedium, height: PryTheme.Size.iconMedium)
                                .background(preset.iconColor.opacity(PryTheme.Opacity.badge))
                                .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))

                            VStack(alignment: .leading, spacing: PryTheme.Spacing.xxs) {
                                Text(preset.rawValue)
                                    .font(PryTheme.Typography.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(PryTheme.Colors.textPrimary)
                                Text(preset.description)
                                    .font(PryTheme.Typography.detail)
                                    .foregroundStyle(PryTheme.Colors.textTertiary)
                            }

                            Spacer()

                            if store.networkThrottle == preset {
                                Image(systemName: "checkmark")
                                    .font(PryTheme.Typography.detail)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(PryTheme.Colors.accent)
                            }
                        }
                    }
                }
            } footer: {
                Text("Simulates network latency and failures. Applies to all intercepted requests in real time.")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }
            .listRowBackground(PryTheme.Colors.surface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .pryBackground()
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
        case .none: PryTheme.Colors.success
        case .slow3G: PryTheme.Colors.warning
        case .fast3G: PryTheme.Colors.accent
        case .lossy: PryTheme.Colors.error
        case .offline: PryTheme.Colors.textTertiary
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
