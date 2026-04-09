import SwiftUI

/// Root view of the Pro inspector. Same three-tab layout as the Free
/// ``PryRootView`` but the Network and App tabs wrap the Free monitors
/// and add toolbar / sheet / navigation entries that expose mock rules,
/// breakpoints, session export, throttle and performance metrics.
package struct PryProRootView: View {
    @Bindable var proStore: PryProStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int = 0

    private var store: PryStore { proStore.store }

    package init(proStore: PryProStore) {
        self.proStore = proStore
    }

    package var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Network", systemImage: "network", value: 0) {
                networkTab
            }
            .badge(store.networkEntries.count)

            Tab("Console", systemImage: "terminal", value: 1) {
                consoleTab
            }
            .badge(store.logEntries.count)

            Tab("App", systemImage: "square.grid.2x2", value: 2) {
                appTab
            }
            .badge(store.deeplinkEntries.count + store.pushNotificationEntries.count)
        }
        .pryBackground()
        .environment(\.pryProStore, proStore)
    }

    // MARK: - Tabs

    private var networkTab: some View {
        NavigationStack {
            PryProNetworkMonitorWrapper(proStore: proStore)
                .navigationTitle("Network")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { dismissButton }
        }
    }

    private var consoleTab: some View {
        NavigationStack {
            ConsoleMonitorView(store: store)
                .navigationTitle("Console")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { dismissButton }
        }
    }

    private var appTab: some View {
        NavigationStack {
            PryProAppHubView(proStore: proStore)
                .navigationTitle("App")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { dismissButton }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var dismissButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(PryTheme.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(PryTheme.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Network Monitor Wrapper

/// Wraps the Free ``NetworkMonitorView`` and injects Pro toolbar items
/// (rules nav link + export sheet). SwiftUI merges the outer `.toolbar`
/// modifier with the one inside the Free view so the Pro items appear
/// alongside the Free filter button.
private struct PryProNetworkMonitorWrapper: View {
    @Bindable var proStore: PryProStore
    @State private var showExportSheet = false

    private var rulesCount: Int {
        proStore.mockRules.filter(\.isEnabled).count
        + proStore.breakpointRules.filter(\.isEnabled).count
    }

    var body: some View {
        NetworkMonitorView(store: proStore.store)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        NetworkRulesView(store: proStore)
                            .navigationTitle("Rules")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Image(systemName: rulesCount > 0 ? "bolt.circle.fill" : "bolt.circle")
                            .font(PryTheme.Typography.body)
                            .foregroundStyle(rulesCount > 0 ? PryTheme.Colors.warning : PryTheme.Colors.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(PryTheme.Typography.body)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
                    }
                    .disabled(proStore.store.networkEntries.isEmpty)
                }
            }
            .sheet(isPresented: $showExportSheet) {
                PryProExportSheet(entries: proStore.store.networkEntries)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(PryTheme.Colors.background)
            }
    }
}

// MARK: - Export Sheet

private struct PryProExportSheet: View {
    let entries: [NetworkEntry]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(
                title: "Export",
                trailingAction: .close { dismiss() }
            )

            ScrollView {
                VStack(spacing: PryTheme.Spacing.md) {
                    Text("\(entries.count) requests")
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                        .padding(.top, PryTheme.Spacing.md)

                    exportRow(
                        icon: "shippingbox",
                        title: "Postman Collection",
                        detail: "Import directly into Postman",
                        color: PryTheme.Colors.warning,
                        content: SessionExporter.postmanCollection(entries: entries)
                    )

                    exportRow(
                        icon: "terminal",
                        title: "cURL Commands",
                        detail: "All requests as cURL",
                        color: PryTheme.Colors.success,
                        content: SessionExporter.curlCollection(entries: entries)
                    )

                    exportRow(
                        icon: "doc.text",
                        title: "HAR Archive",
                        detail: "HTTP Archive format (Chrome DevTools)",
                        color: PryTheme.Colors.accent,
                        content: SessionExporter.harArchive(entries: entries)
                    )
                }
                .padding(.horizontal, PryTheme.Spacing.lg)
                .padding(.bottom, PryTheme.Spacing.xl)
            }
        }
        .pryBackground()
    }

    private func exportRow(icon: String, title: String, detail: String, color: Color, content: String) -> some View {
        ShareLink(item: content) {
            HStack(spacing: PryTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(color)
                    .frame(width: PryTheme.Size.iconLarge, height: PryTheme.Size.iconLarge)
                    .background(color.opacity(PryTheme.Opacity.badge))
                    .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))

                VStack(alignment: .leading, spacing: PryTheme.Spacing.xxs) {
                    Text(title)
                        .font(PryTheme.Typography.body)
                        .fontWeight(.medium)
                        .foregroundStyle(PryTheme.Colors.textPrimary)

                    Text(detail)
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }

                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }
            .padding(PryTheme.Spacing.md)
            .background(PryTheme.Colors.surface)
            .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
        }
    }
}
