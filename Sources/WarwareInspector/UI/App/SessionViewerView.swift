import SwiftUI

/// Displays an imported .warware session in read-only mode.
struct SessionViewerView: View {
    let store: InspectorStore
    let deviceInfo: SessionFile.DeviceInfo

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            InspectorRootView(store: store)
                .environment(\.inspectorStore, store)
                .safeAreaInset(edge: .top, spacing: 0) {
                    sessionBanner
                }
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
        VStack(spacing: 0) {
            HStack(spacing: InspectorTheme.Spacing.sm) {
                Image(systemName: "doc.zipper")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.warning)

                Text("Imported Session")
                    .font(InspectorTheme.Typography.detail)
                    .fontWeight(.semibold)
                    .foregroundStyle(InspectorTheme.Colors.warning)

                Text("from \(deviceInfo.name)")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)

                Spacer()

                if let version = deviceInfo.appVersion {
                    Text("v\(version)")
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }
            }
            .padding(.horizontal, InspectorTheme.Spacing.lg)
            .padding(.vertical, InspectorTheme.Spacing.sm)
            .background(InspectorTheme.Colors.warning.opacity(0.1))

            Divider().overlay(InspectorTheme.Colors.border)
        }
    }
}
