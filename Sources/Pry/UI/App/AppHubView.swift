import SwiftUI
import UIKit

/// Hub view with cards differentiated by type: Monitor (live), Storage, Diagnostics, Config.
///
/// The generic `Extras` parameter lets PryPro inject additional sections
/// (Performance, Throttle, Share Session) after Diagnostics without
/// duplicating the hub layout.
@_spi(PryPro) public struct AppHubView<Extras: View>: View {
    @Bindable @_spi(PryPro) public var store: PryStore
    @ViewBuilder @_spi(PryPro) public let extras: () -> Extras
    private var accent: Color { PryTheme.Colors.accent }

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
            }
            .padding(.horizontal, PryTheme.Spacing.lg)
            .padding(.top, PryTheme.Spacing.sm)
            .padding(.bottom, PryTheme.Spacing.xl)
        }
        .pryBackground()
    }

    // MARK: - Monitor Section (live data with context)

    private var monitorSection: some View {
        VStack(spacing: 0) {
            NavigationLink {
                DeeplinkMonitorView(store: store)
                    .navigationTitle("Deeplinks")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                hubRow(
                    icon: "link",
                    title: "Deeplinks",
                    subtitle: lastDeeplinkSubtitle,
                    badge: store.deeplinkEntries.count
                )
            }

            rowDivider

            NavigationLink {
                PushNotificationsView(store: store)
                    .navigationTitle("Push Notifications")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                hubRow(
                    icon: "bell.badge",
                    title: "Push Notifications",
                    subtitle: lastPushSubtitle,
                    badge: store.pushNotificationEntries.count
                )
            }
        }
        .background(PryTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: PryTheme.Radius.lg))
        .pryGlowBorder()
    }

    private var lastDeeplinkSubtitle: String {
        guard let last = store.deeplinkEntries.first else { return "Waiting for deeplink events" }
        return "\(last.schemeAndHost)\(last.path) \u{00B7} \(last.timestamp.relativeTimestamp)"
    }

    private var lastPushSubtitle: String {
        guard let last = store.pushNotificationEntries.first else { return "Waiting for push notifications" }
        return "\(last.displayTitle) \u{00B7} \(last.timestamp.relativeTimestamp)"
    }

    // MARK: - Storage Section

    private var storageSection: some View {
        VStack(spacing: 0) {
            NavigationLink {
                CookiesView()
                    .navigationTitle("Cookies")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                hubRow(
                    icon: "birthday.cake",
                    title: "Cookies",
                    subtitle: "\(HTTPCookieStorage.shared.cookies?.count ?? 0) stored cookies"
                )
            }

            rowDivider

            NavigationLink {
                UserDefaultsView()
                    .navigationTitle("UserDefaults")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                hubRow(
                    icon: "tray.full",
                    title: "UserDefaults",
                    subtitle: "\(UserDefaults.standard.dictionaryRepresentation().count) keys stored"
                )
            }
        }
        .background(PryTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: PryTheme.Radius.lg))
        .pryGlowBorder()
    }

    // MARK: - Diagnostics Section

    private var diagnosticsSection: some View {
        VStack(spacing: 0) {
            NavigationLink {
                EnvironmentView()
                    .navigationTitle("Device & App")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                hubRow(
                    icon: "iphone",
                    title: "Device & App",
                    subtitle: "\(UIDevice.current.name) \u{00B7} iOS \(UIDevice.current.systemVersion)"
                )
            }

            rowDivider

            NavigationLink {
                PermissionsView()
                    .navigationTitle("Permissions")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                hubRow(
                    icon: "lock.shield",
                    title: "Permissions",
                    subtitle: "Camera, location, notifications..."
                )
            }
        }
        .background(PryTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: PryTheme.Radius.lg))
        .pryGlowBorder()
    }

    // MARK: - Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(PryTheme.Typography.sectionLabel)
            .tracking(PryTheme.Text.tracking)
            .foregroundStyle(PryTheme.Colors.textTertiary)
            .padding(.bottom, PryTheme.Spacing.sm)
    }

    private func hubRow(icon: String, title: String, subtitle: String, badge: Int? = nil) -> some View {
        HStack(spacing: PryTheme.Spacing.md) {
            iconPill(systemName: icon)

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

            if let badge, badge > 0 {
                Text("\(badge)")
                    .font(PryTheme.Typography.detail)
                    .fontWeight(.bold)
                    .padding(.horizontal, PryTheme.Spacing.sm)
                    .padding(.vertical, PryTheme.Spacing.xxs)
                    .background(accent.opacity(PryTheme.Opacity.badge))
                    .foregroundStyle(accent)
                    .clipShape(.capsule)
            }

            Image(systemName: "chevron.right")
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
        .padding(.horizontal, PryTheme.Spacing.lg)
        .frame(minHeight: 52)
    }

    private func iconPill(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(PryTheme.Typography.body)
            .fontWeight(.medium)
            .foregroundStyle(accent)
            .frame(width: PryTheme.Size.iconLarge, height: PryTheme.Size.iconLarge)
            .background(accent.opacity(PryTheme.Opacity.badge))
            .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
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
