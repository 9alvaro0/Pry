import SwiftUI
import LocalAuthentication

// MARK: - Public View Modifiers

extension View {

    /// Attaches the Pry inspector overlay to this view.
    ///
    /// One line is all you need:
    /// ```swift
    /// ContentView()
    ///     .pry()
    /// ```
    ///
    /// The store is created automatically. Access it from any child
    /// view via `@Environment(\.pryStore)` for manual logging.
    public func pry(
        trigger: PryTrigger = .default
    ) -> some View {
        modifier(PryAutoStoreModifier(trigger: trigger))
    }

    /// Attaches the Pry inspector with a custom store.
    ///
    /// Use this overload when you need to configure entry limits:
    /// ```swift
    /// @State private var store = PryStore(maxNetworkEntries: 500)
    ///
    /// ContentView()
    ///     .pry(store: store)
    /// ```
    public func pry(
        store: PryStore,
        trigger: PryTrigger = .default
    ) -> some View {
        modifier(PryOverlayModifier(store: store, trigger: trigger) { store in
            PryRootView(store: store)
        })
    }

    /// Injects the inspector store into the environment without any UI.
    ///
    /// Use this when you want to control presentation yourself:
    /// ```swift
    /// ContentView()
    ///     .pryEnvironment(store: store)
    ///     .sheet(isPresented: $showInspector) {
    ///         PryContentView()
    ///     }
    /// ```
    public func pryEnvironment(store: PryStore) -> some View {
        modifier(PryEnvironmentModifier(store: store))
    }
}

// MARK: - Environment-Only Modifier

struct PryEnvironmentModifier: ViewModifier {
    let store: PryStore

    func body(content: Content) -> some View {
        content
            .environment(\.pryStore, store)
            .onOpenURL { url in
                store.logDeeplink(url: url)
            }
            .onAppear {
                PryLifecycle.start(store: store)
            }
    }
}

// MARK: - Overlay Modifier (includes environment)

/// Generic overlay modifier. Parameterized by the root view type so PryPro
/// can present its own root while reusing the FAB, shake and lifecycle
/// plumbing.
@_spi(PryPro) public struct PryOverlayModifier<Root: View>: ViewModifier {
    @Bindable @_spi(PryPro) public var store: PryStore
    @_spi(PryPro) public let trigger: PryTrigger
    @_spi(PryPro) public let rootViewBuilder: (PryStore) -> Root
    @_spi(PryPro) public var glowColor: Color? = nil

    @State private var isPresented = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var dragResetTask: Task<Void, Never>?
    @State private var isAuthenticating = false

    @_spi(PryPro) public init(
        store: PryStore,
        trigger: PryTrigger,
        glowColor: Color? = nil,
        @ViewBuilder rootViewBuilder: @escaping (PryStore) -> Root
    ) {
        self.store = store
        self.trigger = trigger
        self.glowColor = glowColor
        self.rootViewBuilder = rootViewBuilder
    }

    private var activeTrigger: PryTrigger {
        store.triggerOverride ?? trigger
    }

    private var errorCount: Int {
        store.networkEntries.filter {
            ($0.responseStatusCode ?? 0) >= 400 || $0.responseError != nil
        }.count
    }

    @_spi(PryPro) public func body(content: Content) -> some View {
        content
            .environment(\.pryStore, store)
            .onOpenURL { url in
                store.logDeeplink(url: url)
            }
            .onAppear {
                PryLifecycle.start(store: store)
            }
            .overlay(alignment: store.fabOnLeft ? .bottomLeading : .bottomTrailing) {
                if activeTrigger.contains(.floatingButton) {
                    if store.fabDraggable {
                        fabView
                            .offset(x: store.fabDragOffset.width + dragOffset.width,
                                    y: store.fabDragOffset.height + dragOffset.height)
                            .simultaneousGesture(fabDragGesture)
                            .padding(store.fabOnLeft ? .leading : .trailing, PryTheme.Spacing.xl)
                            .padding(.bottom, PryTheme.Spacing.sm)
                    } else {
                        fabView
                            .padding(store.fabOnLeft ? .leading : .trailing, PryTheme.Spacing.xl)
                            .padding(.bottom, PryTheme.Spacing.sm)
                    }
                }
            }
            .onChange(of: store.fabDraggable) {
                if !store.fabDraggable {
                    store.fabDragOffset = .zero
                    dragOffset = .zero
                }
            }
            .onShake(enabled: activeTrigger.contains(.shake)) {
                openInspector()
            }
            .sheet(isPresented: $isPresented) {
                rootViewBuilder(store)
                    .environment(\.pryStore, store)
                    .environment(\.pryProGlow, glowColor)
                    .prySheetStyle()
            }
    }

    // MARK: - FAB

    private var fabView: some View {
        FloatingActionButtonView(
            icon: "ladybug.fill",
            backgroundColor: PryTheme.Colors.fab,
            foregroundColor: PryTheme.Colors.fabForeground,
            size: PryTheme.Size.fab,
            glowColor: glowColor
        ) {
            guard !isDragging else { return }
            openInspector()
        }
        .overlay(alignment: .topTrailing) {
            if store.showErrorBadge && errorCount > 0 {
                Text("\(errorCount)")
                    .font(PryTheme.Typography.detail)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(PryTheme.Colors.error)
                    .clipShape(.capsule)
                    .offset(x: 4, y: -4)
            }
        }
    }

    // MARK: - Auth

    private func openInspector() {
        guard store.requireAuth else {
            isPresented = true
            return
        }
        guard !isAuthenticating else { return }
        isAuthenticating = true

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isPresented = true
            isAuthenticating = false
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Open Pry Inspector") { success, _ in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success { isPresented = true }
            }
        }
    }

    private var fabDragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation
            }
            .onEnded { value in
                store.fabDragOffset = CGSize(
                    width: store.fabDragOffset.width + value.translation.width,
                    height: store.fabDragOffset.height + value.translation.height
                )
                dragOffset = .zero
                // Delay reset so the Button's tap gesture doesn't fire after drag ends
                dragResetTask?.cancel()
                dragResetTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    isDragging = false
                }
            }
    }
}

// MARK: - Auto Store Modifier

/// Creates and owns a `PryStore` internally so the caller only needs `.pry()`.
private struct PryAutoStoreModifier: ViewModifier {
    @State private var store = PryStore()
    let trigger: PryTrigger

    func body(content: Content) -> some View {
        content
            .pry(store: store, trigger: trigger)
    }
}
