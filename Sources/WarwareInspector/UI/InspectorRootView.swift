import SwiftUI

struct InspectorRootView: View {
    @Bindable var store: InspectorStore

    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var exportURL: URL?
    @State private var selectedTab: Int = 0
    @State private var isExporting: Bool = false
    @State private var exportPhase: ExportPhase = .deviceInfo
    @State private var showClearConfirmation = false
    @State private var pendingClearAction: (() -> Void)?

    var body: some View {
        TabView(selection: $selectedTab) {
            networkTab
                .tabItem { Label("Network", systemImage: "network") }
                .badge(store.networkEntries.count)
                .tag(0)

            consoleTab
                .tabItem { Label("Console", systemImage: "terminal") }
                .badge(store.logEntries.count)
                .tag(1)

            deeplinksTab
                .tabItem { Label("Deeplinks", systemImage: "link") }
                .badge(store.deeplinkEntries.count)
                .tag(2)
        }
        .inspectorBackground()
        .overlay {
            if isExporting { exportOverlay }
        }
        .alert("Clear entries?", isPresented: $showClearConfirmation) {
            Button("Clear", role: .destructive) {
                pendingClearAction?()
                pendingClearAction = nil
            }
            Button("Cancel", role: .cancel) {
                pendingClearAction = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Export Overlay

    private var exportOverlay: some View {
        InspectorTheme.Colors.overlay
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: InspectorTheme.Spacing.xl) {
                    ProgressView()
                        .controlSize(.large)
                    Text(exportPhase.message)
                        .font(InspectorTheme.Typography.subheading)
                        .foregroundStyle(InspectorTheme.Colors.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.2), value: exportPhase.message)
                }
                .frame(width: InspectorTheme.Size.exportDialog)
                .padding(.vertical, InspectorTheme.Spacing.xxl + InspectorTheme.Spacing.sm)
                .background(.ultraThickMaterial)
                .clipShape(.rect(cornerRadius: InspectorTheme.Radius.lg + InspectorTheme.Spacing.xs))
            }
    }

    // MARK: - Tabs

    private var networkTab: some View {
        NavigationStack {
            NetworkMonitorView(store: store)
                .navigationTitle("Network")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarItems { store.clearNetwork() } }
                .sheet(item: $exportURL) { url in
                    ShareSheetView(activityItems: [url])
                }
        }
    }

    private var consoleTab: some View {
        NavigationStack {
            ConsoleMonitorView(store: store)
                .navigationTitle("Console")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarItems { store.clearLogs() } }
        }
    }

    private var deeplinksTab: some View {
        NavigationStack {
            DeeplinkMonitorView(store: store)
                .navigationTitle("Deeplinks")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarItems { store.clearDeeplinks() } }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func toolbarItems(clearAction: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(InspectorTheme.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(InspectorTheme.Colors.textSecondary)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                pendingClearAction = clearAction
                showClearConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(InspectorTheme.Typography.body)
                    .foregroundStyle(InspectorTheme.Colors.textSecondary)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await exportLogs() }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(InspectorTheme.Typography.body)
                    .foregroundStyle(InspectorTheme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Export

    private func exportLogs() async {
        exportPhase = .deviceInfo
        isExporting = true

        let url = await InspectorExporter.shareExport(
            networkEntries: store.networkEntries,
            logEntries: store.logEntries,
            deeplinkEntries: store.deeplinkEntries
        ) { phase in
            withAnimation { exportPhase = phase }
        }

        isExporting = false
        if let url { exportURL = url }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Full Inspector") {
    InspectorRootView(store: .preview)
}

#Preview("Empty") {
    InspectorRootView(store: InspectorStore())
}

#Preview("FAB + Error Badge") {
    Text("My App Content")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .inspector(store: .preview, trigger: .floatingButton)
}

#Preview("FAB - No Errors") {
    Text("My App Content")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .inspector(store: {
            let s = InspectorStore()
            s.addNetworkEntry(.mockSuccess)
            s.addNetworkEntry(.mockNoAuth)
            return s
        }(), trigger: .floatingButton)
}

#Preview("Shake Trigger") {
    Text("Shake the device to open")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .inspector(store: .preview, trigger: .shake)
}

#Preview("Both Triggers") {
    Text("Button + Shake")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .inspector(store: .preview, trigger: [.floatingButton, .shake])
}

#Preview("Embedded as Tab") {
    TabView {
        Text("Home")
            .tabItem { Label("Home", systemImage: "house") }

        InspectorContentView()
            .tabItem { Label("Debug", systemImage: "ladybug") }
    }
    .environment(\.inspectorStore, .preview)
}

#Preview("Environment Only") {
    NavigationStack {
        List {
            NavigationLink("Open Inspector") {
                InspectorContentView()
            }
        }
        .navigationTitle("My App")
    }
    .environment(\.inspectorStore, .preview)
}
#endif
