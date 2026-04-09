import SwiftUI
import UIKit

/// Hub view with cards differentiated by type: Monitor (live), Storage, Diagnostics, Config.
///
/// The generic `Extras` parameter lets PryPro inject additional sections
/// (Performance, Throttle, Share Session) between Diagnostics and
/// Settings without duplicating the hub layout.
@_spi(PryPro) public struct AppHubView<Extras: View>: View {
    @Bindable @_spi(PryPro) public var store: PryStore
    @ViewBuilder @_spi(PryPro) public let extras: () -> Extras

    @_spi(PryPro) public init(store: PryStore, @ViewBuilder extras: @escaping () -> Extras) {
        self.store = store
        self.extras = extras
    }

    @_spi(PryPro) public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MONITOR
                sectionHeader("Monitor")
                monitorSection
                    .padding(.bottom, PryTheme.Spacing.xl)

                // STORAGE
                sectionHeader("Storage")
                storageSection
                    .padding(.bottom, PryTheme.Spacing.xl)

                // DIAGNOSTICS
                sectionHeader("Diagnostics")
                diagnosticsSection
                    .padding(.bottom, PryTheme.Spacing.xl)

                // Extra sections injected by PryPro
                extras()
                    .padding(.bottom, PryTheme.Spacing.xxl)

                // SETTINGS
                Divider().overlay(PryTheme.Colors.border)
                    .padding(.bottom, PryTheme.Spacing.md)
                settingsRow
            }
            .padding(.horizontal, PryTheme.Spacing.lg)
            .padding(.top, PryTheme.Spacing.sm)
            .padding(.bottom, PryTheme.Spacing.xl)
        }
        .pryBackground()
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
                    color: PryTheme.Colors.deeplinks,
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
                    color: PryTheme.Colors.warning,
                    count: store.pushNotificationEntries.count,
                    subtitle: lastPushSubtitle
                )
            }
        }
        .clipShape(.rect(cornerRadius: PryTheme.Radius.lg))
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
                    color: PryTheme.Colors.warning,
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
                    color: PryTheme.Colors.success,
                    detail: "\(UserDefaults.standard.dictionaryRepresentation().count) keys"
                )
            }
        }
        .background(PryTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: PryTheme.Radius.lg))
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
                    color: PryTheme.Colors.success,
                    detail: ""
                )
            }

        }
        .background(PryTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: PryTheme.Radius.lg))
    }

    private var diagnosticsCard: some View {
        HStack(spacing: PryTheme.Spacing.md) {
            Image(systemName: "iphone")
                .font(PryTheme.Typography.body)
                .foregroundStyle(PryTheme.Colors.accent)
                .frame(width: PryTheme.Size.iconLarge, height: PryTheme.Size.iconLarge)
                .background(PryTheme.Colors.accent.opacity(PryTheme.Opacity.badge))
                .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))

            VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                Text("Device & App")
                    .font(PryTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(PryTheme.Colors.textPrimary)

                HStack(spacing: PryTheme.Spacing.xs) {
                    infoPill("iOS \(UIDevice.current.systemVersion)")
                    infoPill("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
                    infoPill(UIDevice.current.name)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
        .padding(.horizontal, PryTheme.Spacing.lg)
        .padding(.vertical, PryTheme.Spacing.md)
    }

    // MARK: - Settings

    private var settingsRow: some View {
        NavigationLink {
            PrySettingsView(store: store)
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
        } label: {
            HStack(spacing: PryTheme.Spacing.md) {
                Image(systemName: "gearshape")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
                    .frame(width: PryTheme.Size.iconMedium, height: PryTheme.Size.iconMedium)
                    .background(PryTheme.Colors.surfaceElevated)
                    .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))

                Text("Settings")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(PryTheme.Colors.textSecondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }
            .padding(.vertical, PryTheme.Spacing.sm)
        }
    }

    // MARK: - Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(PryTheme.Typography.sectionLabel)
            .tracking(PryTheme.Text.tracking)
            .foregroundStyle(PryTheme.Colors.textTertiary)
            .padding(.bottom, PryTheme.Spacing.sm)
    }

    private func monitorCard(icon: String, title: String, color: Color, count: Int, subtitle: String) -> some View {
        HStack(spacing: PryTheme.Spacing.md) {
            Image(systemName: icon)
                .font(PryTheme.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .frame(width: PryTheme.Size.iconLarge, height: PryTheme.Size.iconLarge)
                .background(color.opacity(PryTheme.Opacity.badge))
                .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))

            VStack(alignment: .leading, spacing: PryTheme.Spacing.xxs) {
                Text(title)
                    .font(PryTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(PryTheme.Colors.textPrimary)

                Text(subtitle)
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            if count > 0 {
                Text("\(count)")
                    .font(PryTheme.Typography.detail)
                    .fontWeight(.bold)
                    .padding(.horizontal, PryTheme.Spacing.sm)
                    .padding(.vertical, PryTheme.Spacing.xxs)
                    .background(color.opacity(PryTheme.Opacity.medium))
                    .foregroundStyle(color)
                    .clipShape(.capsule)
            }

            Image(systemName: "chevron.right")
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
        .padding(.horizontal, PryTheme.Spacing.lg)
        .padding(.vertical, PryTheme.Spacing.md)
        .frame(minHeight: PryTheme.Size.rowMinHeight)
        .background(PryTheme.Colors.surface)
    }

    private func storageRow(icon: String, title: String, color: Color, detail: String) -> some View {
        HStack(spacing: PryTheme.Spacing.md) {
            Image(systemName: icon)
                .font(PryTheme.Typography.body)
                .foregroundStyle(color)
                .frame(width: PryTheme.Size.iconMedium, height: PryTheme.Size.iconMedium)
                .background(color.opacity(PryTheme.Opacity.tint))
                .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))

            Text(title)
                .font(PryTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(PryTheme.Colors.textPrimary)

            Spacer()

            Text(detail)
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)

            Image(systemName: "chevron.right")
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
        .padding(.horizontal, PryTheme.Spacing.lg)
        .padding(.vertical, PryTheme.Spacing.md)
    }

    private func infoPill(_ text: String) -> some View {
        Text(text)
            .font(PryTheme.Typography.detail)
            .foregroundStyle(PryTheme.Colors.textTertiary)
            .padding(.horizontal, PryTheme.Spacing.xs)
            .padding(.vertical, PryTheme.Spacing.xxs)
            .background(PryTheme.Colors.surfaceElevated)
            .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))
    }

    private var rowDivider: some View {
        Divider()
            .overlay(PryTheme.Colors.border)
            .padding(.leading, PryTheme.Size.methodColumn + PryTheme.Spacing.pip)
    }
}

// MARK: - Convenience Free Init

extension AppHubView where Extras == EmptyView {
    @_spi(PryPro) public init(store: PryStore) {
        self.init(store: store) { EmptyView() }
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
        AppHubView(store: PryStore())
            .navigationTitle("App")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
