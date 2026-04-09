import SwiftUI

/// Pro variant of the App hub. Reuses the Free ``AppHubView`` layout via
/// its generic `Extras` slot and injects a Tools section plus a Performance
/// entry that lets Pro users reach the throttle, share session and
/// performance metrics views.
struct PryProAppHubView: View {
    @Bindable var proStore: PryProStore
    @State private var showFileImporter = false
    @State private var importedSession: ImportedSessionWrapper?

    private var store: PryStore { proStore.store }

    var body: some View {
        AppHubView(store: store) {
            toolsSection
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json, .data]) { result in
            if case .success(let url) = result,
               let session = SessionFileManager.importSession(from: url) {
                importedSession = ImportedSessionWrapper(store: session.store, metadata: session.metadata)
            }
        }
        .sheet(item: $importedSession) { wrapper in
            SessionViewerView(store: wrapper.store, deviceInfo: wrapper.metadata)
        }
    }

    // MARK: - Tools Section

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Tools")

            VStack(spacing: 0) {
                NavigationLink {
                    NetworkThrottleView(store: proStore)
                        .navigationTitle("Network Conditions")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    toolRow(
                        icon: proStore.networkThrottle.icon,
                        title: "Network Conditions",
                        color: proStore.networkThrottle.iconColor,
                        detail: proStore.networkThrottle != .none ? proStore.networkThrottle.rawValue : nil,
                        showChevron: true
                    )
                }

                rowDivider

                NavigationLink {
                    PerformanceView()
                        .navigationTitle("Performance")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    toolRow(
                        icon: "gauge.high",
                        title: "Performance",
                        color: PryTheme.Colors.error,
                        detail: nil,
                        showChevron: true
                    )
                }

                rowDivider

                if let url = SessionFileManager.export(store: store) {
                    ShareLink(item: url) {
                        toolRow(
                            icon: "square.and.arrow.up",
                            title: "Share Session",
                            color: PryTheme.Colors.accent,
                            detail: "\(store.networkEntries.count + store.logEntries.count) entries",
                            showChevron: false
                        )
                    }
                }

                rowDivider

                Button {
                    showFileImporter = true
                } label: {
                    toolRow(
                        icon: "square.and.arrow.down",
                        title: "Open Session",
                        color: PryTheme.Colors.warning,
                        detail: nil,
                        showChevron: false
                    )
                }
            }
            .background(PryTheme.Colors.surface)
            .clipShape(.rect(cornerRadius: PryTheme.Radius.lg))
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

    private func toolRow(icon: String, title: String, color: Color, detail: String?, showChevron: Bool) -> some View {
        HStack(spacing: PryTheme.Spacing.md) {
            Image(systemName: icon)
                .font(PryTheme.Typography.body)
                .foregroundStyle(color)
                .frame(width: PryTheme.Size.iconMedium, height: PryTheme.Size.iconMedium)
                .background(color.opacity(PryTheme.Opacity.badge))
                .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))

            Text(title)
                .font(PryTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(PryTheme.Colors.textPrimary)

            Spacer()

            if let detail {
                Text(detail)
                    .font(PryTheme.Typography.detail)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, PryTheme.Spacing.lg)
        .padding(.vertical, PryTheme.Spacing.md)
    }

    private var rowDivider: some View {
        Divider()
            .overlay(PryTheme.Colors.border)
            .padding(.leading, PryTheme.Size.methodColumn + PryTheme.Spacing.pip)
    }
}

// MARK: - Imported Session Wrapper

private struct ImportedSessionWrapper: Identifiable {
    let id = UUID()
    let store: PryStore
    let metadata: SessionFile.DeviceInfo
}
