import SwiftUI

struct InspectorRootView: View {
    @Bindable var store: InspectorStore

    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int = 0

    var body: some View {
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
        .inspectorBackground()
    }

    // MARK: - Tabs

    private var networkTab: some View {
        NavigationStack {
            NetworkMonitorView(store: store)
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
            AppHubView(store: store)
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
                    .font(InspectorTheme.Typography.body)
                    .fontWeight(.semibold)
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
