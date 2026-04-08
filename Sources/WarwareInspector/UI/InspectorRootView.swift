import SwiftUI

struct InspectorRootView: View {
    @Bindable var store: InspectorStore

    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int = 0
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

    // MARK: - Tabs

    private var networkTab: some View {
        NavigationStack {
            NetworkMonitorView(store: store)
                .navigationTitle("Network")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarItems { store.clearNetwork() } }
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
