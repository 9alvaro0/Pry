import SwiftUI

@_spi(PryPro) public struct PryRootView: View {
    @Bindable @_spi(PryPro) public var store: PryStore

    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int = 0

    @_spi(PryPro) public init(store: PryStore) {
        self.store = store
    }

    @_spi(PryPro) public var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Network", systemImage: "network", value: 0) {
                networkTab
            }

            Tab("Console", systemImage: "terminal", value: 1) {
                consoleTab
            }

            Tab("App", systemImage: "square.grid.2x2", value: 2) {
                appTab
            }
        }
        .tint(PryTheme.Colors.accent)
        .pryBackground()
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
                .toolbar {
                    dismissButton
                    settingsButton
                }
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

    @ToolbarContentBuilder
    private var settingsButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                PrySettingsView(store: store)
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                Image(systemName: "gearshape")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(PryTheme.Colors.textSecondary)
            }
        }
    }

}

// MARK: - Previews

#if DEBUG
#Preview("Full Inspector") {
    PryRootView(store: .preview)
}

#Preview("Empty") {
    PryRootView(store: PryStore())
}

#Preview("FAB + Error Badge") {
    Text("My App Content")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pry(store: .preview, trigger: .floatingButton)
}

#Preview("FAB - No Errors") {
    Text("My App Content")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pry(store: {
            let s = PryStore()
            s.addNetworkEntry(.mockSuccess)
            s.addNetworkEntry(.mockNoAuth)
            return s
        }(), trigger: .floatingButton)
}

#Preview("Shake Trigger") {
    Text("Shake the device to open")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pry(store: .preview, trigger: .shake)
}

#Preview("Both Triggers") {
    Text("Button + Shake")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pry(store: .preview, trigger: [.floatingButton, .shake])
}

#Preview("Embedded as Tab") {
    TabView {
        Text("Home")
            .tabItem { Label("Home", systemImage: "house") }

        PryContentView()
            .tabItem { Label("Debug", systemImage: "ladybug") }
    }
    .environment(\.pryStore, .preview)
}

#Preview("Environment Only") {
    NavigationStack {
        List {
            NavigationLink("Open Inspector") {
                PryContentView()
            }
        }
        .navigationTitle("My App")
    }
    .environment(\.pryStore, .preview)
}
#endif
