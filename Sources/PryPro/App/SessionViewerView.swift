import SwiftUI

/// Displays an imported .pry session in read-only mode.
/// Only shows Network and Console tabs (no App hub since it's not relevant).
struct SessionViewerView: View {
    let store: PryStore
    let deviceInfo: SessionFile.DeviceInfo

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sessionBanner

                TabView(selection: $selectedTab) {
                    Tab("Network", systemImage: "network", value: 0) {
                        NavigationStack {
                            NetworkMonitorView(store: store)
                                .navigationTitle("Network")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                    .badge(store.networkEntries.count)

                    Tab("Console", systemImage: "terminal", value: 1) {
                        NavigationStack {
                            ConsoleMonitorView(store: store)
                                .navigationTitle("Console")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                    .badge(store.logEntries.count)
                }
            }
            .environment(\.pryStore, store)
            .environment(\.pryReadOnly, true)
            .pryBackground()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(PryTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private var sessionBanner: some View {
        HStack(spacing: PryTheme.Spacing.sm) {
            Image(systemName: "doc.zipper")
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.warning)

            Text(deviceInfo.name)
                .font(PryTheme.Typography.detail)
                .fontWeight(.medium)
                .foregroundStyle(PryTheme.Colors.textPrimary)

            Text("iOS \(deviceInfo.systemVersion)")
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)

            Spacer()

            if let app = deviceInfo.appName, let version = deviceInfo.appVersion {
                Text("\(app) v\(version)")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, PryTheme.Spacing.lg)
        .padding(.vertical, PryTheme.Spacing.xs)
        .background(PryTheme.Colors.warning.opacity(PryTheme.Opacity.border))
    }
}
