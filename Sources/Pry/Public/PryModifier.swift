import SwiftUI

// MARK: - Public View Modifiers

extension View {

    /// Attaches the Pry inspector overlay to this view.
    ///
    /// This single modifier does everything:
    /// - Registers the URLProtocol interceptor
    /// - Injects the store into the environment
    /// - Captures deeplinks via `.onOpenURL`
    /// - Shows the trigger UI (floating button, shake, or both)
    ///
    /// ```swift
    /// @State private var store = PryStore()
    ///
    /// ContentView()
    ///     .pry(store: store)
    ///     .pry(store: store, trigger: .shake)
    ///     .pry(store: store, trigger: [.floatingButton, .shake])
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

    @State private var isPresented = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    @_spi(PryPro) public init(
        store: PryStore,
        trigger: PryTrigger,
        @ViewBuilder rootViewBuilder: @escaping (PryStore) -> Root
    ) {
        self.store = store
        self.trigger = trigger
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
                isPresented = true
            }
            .sheet(isPresented: $isPresented) {
                rootViewBuilder(store)
                    .environment(\.pryStore, store)
            }
    }

    // MARK: - FAB

    private var fabView: some View {
        FloatingActionButtonView(
            icon: "ladybug.fill",
            backgroundColor: PryTheme.Colors.fab,
            foregroundColor: PryTheme.Colors.fabForeground,
            size: PryTheme.Size.fab
        ) {
            guard !isDragging else { return }
            isPresented = true
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
                Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    isDragging = false
                }
            }
    }
}
