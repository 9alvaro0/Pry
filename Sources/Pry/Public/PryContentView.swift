import SwiftUI

/// Public view that displays the full inspector interface.
///
/// Use this to embed the inspector anywhere in your app:
///
/// ```swift
/// // As a tab
/// TabView {
///     MyHomeView()
///     PryContentView()
///         .tabItem { Label("Debug", systemImage: "ladybug") }
/// }
/// .environment(\.pryStore, store)
///
/// // As a NavigationLink destination
/// NavigationLink("Inspector") {
///     PryContentView()
/// }
///
/// // In a sheet you control
/// .sheet(isPresented: $showInspector) {
///     PryContentView()
/// }
/// ```
public struct PryContentView: View {
    @Environment(\.pryStore) private var store

    /// Creates a new inspector content view. Reads the store from the environment.
    public init() {}

    public var body: some View {
        PryRootView(store: store)
    }
}
