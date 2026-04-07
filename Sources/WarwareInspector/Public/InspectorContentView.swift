import SwiftUI

/// Public view that displays the full inspector interface.
///
/// Use this to embed the inspector anywhere in your app:
///
/// ```swift
/// // As a tab
/// TabView {
///     MyHomeView()
///     InspectorContentView()
///         .tabItem { Label("Debug", systemImage: "ladybug") }
/// }
/// .environment(\.inspectorStore, store)
///
/// // As a NavigationLink destination
/// NavigationLink("Inspector") {
///     InspectorContentView()
/// }
///
/// // In a sheet you control
/// .sheet(isPresented: $showInspector) {
///     InspectorContentView()
/// }
/// ```
public struct InspectorContentView: View {
    @Environment(\.inspectorStore) private var store

    public init() {}

    public var body: some View {
        InspectorRootView(store: store)
    }
}
