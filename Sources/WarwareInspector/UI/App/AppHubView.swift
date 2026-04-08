import SwiftUI

/// Hub view that groups secondary features: Deeplinks, Push Notifications, Device Info.
struct AppHubView: View {
    @Bindable var store: InspectorStore

    var body: some View {
        List {
            Section {
                NavigationLink {
                    DeeplinkMonitorView(store: store)
                        .navigationTitle("Deeplinks")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    hubRow(
                        icon: "link",
                        title: "Deeplinks",
                        color: InspectorTheme.Colors.deeplinks,
                        badge: store.deeplinkEntries.count
                    )
                }

                NavigationLink {
                    PushNotificationsView(store: store)
                        .navigationTitle("Push Notifications")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    hubRow(
                        icon: "bell.badge",
                        title: "Push Notifications",
                        color: InspectorTheme.Colors.warning,
                        badge: store.pushNotificationEntries.count
                    )
                }
            } header: {
                Text("Events")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
            .listRowBackground(InspectorTheme.Colors.surface)

            Section {
                NavigationLink {
                    EnvironmentView()
                        .navigationTitle("Device Info")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    hubRow(
                        icon: "info.circle",
                        title: "Device Info",
                        color: InspectorTheme.Colors.accent
                    )
                }

                NavigationLink {
                    CookiesView()
                        .navigationTitle("Cookies")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    hubRow(
                        icon: "birthday.cake",
                        title: "Cookies",
                        color: InspectorTheme.Colors.warning
                    )
                }

                NavigationLink {
                    UserDefaultsView()
                        .navigationTitle("UserDefaults")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    hubRow(
                        icon: "tray.full",
                        title: "UserDefaults",
                        color: InspectorTheme.Colors.success
                    )
                }
            } header: {
                Text("System")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
            .listRowBackground(InspectorTheme.Colors.surface)

            Section {
                NavigationLink {
                    MockRulesView(store: store)
                        .navigationTitle("Mock Rules")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    hubRow(
                        icon: "theatermasks",
                        title: "Mock Rules",
                        color: InspectorTheme.Colors.syntaxBool,
                        badge: store.mockRules.filter(\.isEnabled).count
                    )
                }

                NavigationLink {
                    InspectorSettingsView(store: store)
                        .navigationTitle("Settings")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    hubRow(
                        icon: "gearshape",
                        title: "Settings",
                        color: InspectorTheme.Colors.textSecondary
                    )
                }
            } header: {
                Text("Configuration")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
            .listRowBackground(InspectorTheme.Colors.surface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .inspectorBackground()
    }

    // MARK: - Row

    private func hubRow(icon: String, title: String, color: Color, badge: Int = 0) -> some View {
        HStack(spacing: InspectorTheme.Spacing.md) {
            Image(systemName: icon)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))

            Text(title)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)

            Spacer()

            if badge > 0 {
                Text("\(badge)")
                    .font(InspectorTheme.Typography.detail)
                    .fontWeight(.semibold)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
        }
        .padding(.vertical, InspectorTheme.Spacing.xs)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("App Hub") {
    NavigationStack {
        AppHubView(store: .preview)
            .navigationTitle("App")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
