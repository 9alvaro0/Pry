import SwiftUI
import UIKit

/// Hub view with cards differentiated by type: Monitor (live), Storage, Diagnostics, Config.
struct AppHubView: View {
    @Bindable var store: InspectorStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MONITOR
                sectionHeader("Monitor")
                monitorSection
                    .padding(.bottom, InspectorTheme.Spacing.xl)

                // STORAGE
                sectionHeader("Storage")
                storageSection
                    .padding(.bottom, InspectorTheme.Spacing.xl)

                // DIAGNOSTICS
                sectionHeader("Diagnostics")
                diagnosticsSection
                    .padding(.bottom, InspectorTheme.Spacing.xl)

                // TOOLS
                sectionHeader("Tools")
                toolsSection
                    .padding(.bottom, InspectorTheme.Spacing.xxl)

                // SETTINGS
                Divider().overlay(InspectorTheme.Colors.border)
                    .padding(.bottom, InspectorTheme.Spacing.md)
                settingsRow
            }
            .padding(.horizontal, InspectorTheme.Spacing.lg)
            .padding(.top, InspectorTheme.Spacing.sm)
            .padding(.bottom, InspectorTheme.Spacing.xl)
        }
        .inspectorBackground()
    }

    // MARK: - Monitor Section (live data with context)

    private var monitorSection: some View {
        VStack(spacing: 1) {
            NavigationLink {
                DeeplinkMonitorView(store: store)
                    .navigationTitle("Deeplinks")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                monitorCard(
                    icon: "link",
                    title: "Deeplinks",
                    color: InspectorTheme.Colors.deeplinks,
                    count: store.deeplinkEntries.count,
                    subtitle: lastDeeplinkSubtitle
                )
            }

            NavigationLink {
                PushNotificationsView(store: store)
                    .navigationTitle("Push Notifications")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                monitorCard(
                    icon: "bell.badge",
                    title: "Push Notifications",
                    color: InspectorTheme.Colors.warning,
                    count: store.pushNotificationEntries.count,
                    subtitle: lastPushSubtitle
                )
            }
        }
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.lg))
    }

    private var lastDeeplinkSubtitle: String {
        guard let last = store.deeplinkEntries.first else { return "No events yet" }
        return "\(last.schemeAndHost)\(last.path)  \(last.timestamp.relativeTimestamp)"
    }

    private var lastPushSubtitle: String {
        guard let last = store.pushNotificationEntries.first else { return "No events yet" }
        return "\(last.displayTitle)  \(last.timestamp.relativeTimestamp)"
    }

    // MARK: - Storage Section

    private var storageSection: some View {
        VStack(spacing: 0) {
            NavigationLink {
                CookiesView()
                    .navigationTitle("Cookies")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                storageRow(
                    icon: "birthday.cake",
                    title: "Cookies",
                    color: InspectorTheme.Colors.warning,
                    detail: "\(HTTPCookieStorage.shared.cookies?.count ?? 0) cookies"
                )
            }

            rowDivider

            NavigationLink {
                UserDefaultsView()
                    .navigationTitle("UserDefaults")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                storageRow(
                    icon: "tray.full",
                    title: "UserDefaults",
                    color: InspectorTheme.Colors.success,
                    detail: "\(UserDefaults.standard.dictionaryRepresentation().count) keys"
                )
            }

            rowDivider

            NavigationLink {
                KeychainView()
                    .navigationTitle("Keychain")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                storageRow(
                    icon: "key",
                    title: "Keychain",
                    color: InspectorTheme.Colors.accent,
                    detail: ""
                )
            }

            rowDivider

            NavigationLink {
                FileBrowserView()
                    .navigationTitle("Sandbox")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                storageRow(
                    icon: "folder",
                    title: "File Browser",
                    color: InspectorTheme.Colors.syntaxNumber,
                    detail: ""
                )
            }
        }
        .background(InspectorTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.lg))
    }

    // MARK: - Diagnostics Section

    private var diagnosticsSection: some View {
        VStack(spacing: 0) {
            NavigationLink {
                EnvironmentView()
                    .navigationTitle("Device & App")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                diagnosticsCard
            }

            rowDivider

            NavigationLink {
                PermissionsView()
                    .navigationTitle("Permissions")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                storageRow(
                    icon: "lock.shield",
                    title: "Permissions",
                    color: InspectorTheme.Colors.success,
                    detail: ""
                )
            }

            rowDivider

            NavigationLink {
                PerformanceView()
                    .navigationTitle("Performance")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                storageRow(
                    icon: "gauge.high",
                    title: "Performance",
                    color: InspectorTheme.Colors.error,
                    detail: ""
                )
            }
        }
        .background(InspectorTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.lg))
    }

    private var diagnosticsCard: some View {
        HStack(spacing: InspectorTheme.Spacing.md) {
            Image(systemName: "iphone")
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.accent)
                .frame(width: 36, height: 36)
                .background(InspectorTheme.Colors.accent.opacity(0.15))
                .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))

            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                Text("Device & App")
                    .font(InspectorTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)

                HStack(spacing: InspectorTheme.Spacing.xs) {
                    infoPill("iOS \(UIDevice.current.systemVersion)")
                    infoPill("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
                    infoPill(UIDevice.current.name)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
        .padding(.horizontal, InspectorTheme.Spacing.lg)
        .padding(.vertical, InspectorTheme.Spacing.md)
    }

    // MARK: - Tools Section

    private var toolsSection: some View {
        VStack(spacing: 0) {
            NavigationLink {
                NetworkThrottleView(store: store)
                    .navigationTitle("Network Conditions")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack(spacing: InspectorTheme.Spacing.md) {
                    Image(systemName: store.networkThrottle.icon)
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(store.networkThrottle.iconColor)
                        .frame(width: 28, height: 28)
                        .background(store.networkThrottle.iconColor.opacity(0.15))
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))

                    Text("Network Conditions")
                        .font(InspectorTheme.Typography.body)
                        .fontWeight(.medium)
                        .foregroundStyle(InspectorTheme.Colors.textPrimary)

                    Spacer()

                    if store.networkThrottle != .none {
                        Text(store.networkThrottle.rawValue)
                            .font(InspectorTheme.Typography.detail)
                            .fontWeight(.semibold)
                            .foregroundStyle(store.networkThrottle.iconColor)
                    }

                    Image(systemName: "chevron.right")
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }
                .padding(.horizontal, InspectorTheme.Spacing.lg)
                .padding(.vertical, InspectorTheme.Spacing.md)
            }
        }
        .background(InspectorTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.lg))
    }

    // MARK: - Settings

    private var settingsRow: some View {
        NavigationLink {
            InspectorSettingsView(store: store)
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
        } label: {
            HStack(spacing: InspectorTheme.Spacing.md) {
                Image(systemName: "gearshape")
                    .font(InspectorTheme.Typography.body)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(InspectorTheme.Colors.surfaceElevated)
                    .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))

                Text("Settings")
                    .font(InspectorTheme.Typography.body)
                    .foregroundStyle(InspectorTheme.Colors.textSecondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
            .padding(.vertical, InspectorTheme.Spacing.sm)
        }
    }

    // MARK: - Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(InspectorTheme.Colors.textTertiary)
            .padding(.bottom, InspectorTheme.Spacing.sm)
    }

    private func monitorCard(icon: String, title: String, color: Color, count: Int, subtitle: String) -> some View {
        HStack(spacing: InspectorTheme.Spacing.md) {
            Image(systemName: icon)
                .font(InspectorTheme.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))

            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                Text(title)
                    .font(InspectorTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)

                Text(subtitle)
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            if count > 0 {
                Text("\(count)")
                    .font(InspectorTheme.Typography.detail)
                    .fontWeight(.bold)
                    .padding(.horizontal, InspectorTheme.Spacing.sm)
                    .padding(.vertical, InspectorTheme.Spacing.xxs)
                    .background(color.opacity(0.2))
                    .foregroundStyle(color)
                    .clipShape(.capsule)
            }

            Image(systemName: "chevron.right")
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
        .padding(.horizontal, InspectorTheme.Spacing.lg)
        .padding(.vertical, InspectorTheme.Spacing.md)
        .frame(minHeight: 72)
        .background(InspectorTheme.Colors.surface)
    }

    private func storageRow(icon: String, title: String, color: Color, detail: String) -> some View {
        HStack(spacing: InspectorTheme.Spacing.md) {
            Image(systemName: icon)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))

            Text(title)
                .font(InspectorTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)

            Spacer()

            Text(detail)
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)

            Image(systemName: "chevron.right")
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
        .padding(.horizontal, InspectorTheme.Spacing.lg)
        .padding(.vertical, InspectorTheme.Spacing.md)
    }

    private func infoPill(_ text: String) -> some View {
        Text(text)
            .font(InspectorTheme.Typography.detail)
            .foregroundStyle(InspectorTheme.Colors.textTertiary)
            .padding(.horizontal, InspectorTheme.Spacing.xs)
            .padding(.vertical, InspectorTheme.Spacing.xxs)
            .background(InspectorTheme.Colors.surfaceElevated)
            .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))
    }

    private var rowDivider: some View {
        Divider()
            .overlay(InspectorTheme.Colors.border)
            .padding(.leading, 58)
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

#Preview("App Hub - Empty") {
    NavigationStack {
        AppHubView(store: InspectorStore())
            .navigationTitle("App")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
