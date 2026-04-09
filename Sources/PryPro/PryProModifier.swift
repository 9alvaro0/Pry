import SwiftUI

// MARK: - Public View Modifier

extension View {

    /// Attaches the Pry inspector with Pro features to this view.
    ///
    /// Identical to `.pry(store:)` but drives everything from a
    /// ``PryProStore`` and presents ``PryProRootView`` (which adds
    /// mock rules, breakpoints, throttle, performance metrics and
    /// advanced session export on top of the Free inspector).
    ///
    /// ```swift
    /// @State private var store = PryProStore()
    ///
    /// var body: some Scene {
    ///     WindowGroup {
    ///         ContentView()
    ///             .pryPro(store: store)
    ///     }
    /// }
    /// ```
    public func pryPro(
        store: PryProStore,
        trigger: PryTrigger = .default
    ) -> some View {
        self
            .environment(\.pryProStore, store)
            .modifier(
                PryOverlayModifier(
                    store: store.store,
                    trigger: trigger
                ) { _ in
                    PryProRootView(proStore: store)
                }
            )
            .modifier(PryProBreakpointModifier())
            .onAppear {
                PryPro.install()
            }
    }
}

// MARK: - Breakpoint Sheet Modifier

/// Presents the breakpoint paused request editor when the network thread
/// has a paused request waiting for user action.
private struct PryProBreakpointModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .sheet(item: Binding(
                get: { BreakpointManager.shared.state.pausedRequest },
                set: { if $0 == nil { BreakpointManager.shared.cancelRequest() } }
            )) { paused in
                BreakpointEditorView(
                    paused: paused,
                    onSend: { BreakpointManager.shared.resumeRequest() },
                    onCancel: { BreakpointManager.shared.cancelRequest() }
                )
                .interactiveDismissDisabled()
            }
    }
}
