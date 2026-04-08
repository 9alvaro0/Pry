import SwiftUI

/// Displays an imported .warware session in read-only mode.
/// Only shows Network and Console tabs (no App hub since it's not relevant).
struct SessionViewerView: View {
    let store: InspectorStore
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
            .environment(\.inspectorStore, store)
            .environment(\.inspectorReadOnly, true)
            .inspectorBackground()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(InspectorTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private var sessionBanner: some View {
        HStack(spacing: InspectorTheme.Spacing.sm) {
            Image(systemName: "doc.zipper")
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.warning)

            Text(deviceInfo.name)
                .font(InspectorTheme.Typography.detail)
                .fontWeight(.medium)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)

            Text("iOS \(deviceInfo.systemVersion)")
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)

            Spacer()

            if let app = deviceInfo.appName, let version = deviceInfo.appVersion {
                Text("\(app) v\(version)")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, InspectorTheme.Spacing.lg)
        .padding(.vertical, InspectorTheme.Spacing.xs)
        .background(InspectorTheme.Colors.warning.opacity(0.1))
    }
}
