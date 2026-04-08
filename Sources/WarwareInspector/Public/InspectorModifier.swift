import SwiftUI

// MARK: - Public View Modifiers

extension View {

    /// Attaches the WarwareInspector to this view.
    ///
    /// This single modifier does everything:
    /// - Registers the URLProtocol interceptor
    /// - Injects the store into the environment
    /// - Captures deeplinks via `.onOpenURL`
    /// - Shows the trigger UI (floating button, shake, or both)
    ///
    /// ```swift
    /// @State private var store = InspectorStore()
    ///
    /// ContentView()
    ///     .inspector(store: store)
    ///     .inspector(store: store, trigger: .shake)
    ///     .inspector(store: store, trigger: [.floatingButton, .shake])
    /// ```
    public func inspector(
        store: InspectorStore,
        trigger: InspectorTrigger = .default
    ) -> some View {
        modifier(InspectorOverlayModifier(store: store, trigger: trigger))
    }

    /// Injects the inspector store into the environment without any UI.
    ///
    /// Use this when you want to control presentation yourself:
    /// ```swift
    /// ContentView()
    ///     .inspectorEnvironment(store: store)
    ///     .sheet(isPresented: $showInspector) {
    ///         InspectorContentView()
    ///     }
    /// ```
    public func inspectorEnvironment(store: InspectorStore) -> some View {
        modifier(InspectorEnvironmentModifier(store: store))
    }
}

// MARK: - Environment-Only Modifier

struct InspectorEnvironmentModifier: ViewModifier {
    let store: InspectorStore

    func body(content: Content) -> some View {
        content
            .environment(\.inspectorStore, store)
            .onOpenURL { url in
                store.logDeeplink(url: url)
            }
            .onAppear {
                InspectorLifecycle.start(store: store)
            }
    }
}

// MARK: - Overlay Modifier (includes environment)

struct InspectorOverlayModifier: ViewModifier {
    @Bindable var store: InspectorStore
    let trigger: InspectorTrigger

    @State private var isPresented = false
    @State private var dragOffset: CGSize = .zero

    private var activeTrigger: InspectorTrigger {
        store.triggerOverride ?? trigger
    }

    private var errorCount: Int {
        store.networkEntries.filter {
            ($0.responseStatusCode ?? 0) >= 400 || $0.responseError != nil
        }.count
    }

    func body(content: Content) -> some View {
        content
            .environment(\.inspectorStore, store)
            .onOpenURL { url in
                store.logDeeplink(url: url)
            }
            .onAppear {
                InspectorLifecycle.start(store: store)
            }
            .overlay(alignment: store.fabOnLeft ? .bottomLeading : .bottomTrailing) {
                if activeTrigger.contains(.floatingButton) {
                    fabView
                        .offset(x: store.fabDragOffset.width + dragOffset.width,
                                y: store.fabDragOffset.height + dragOffset.height)
                        .gesture(store.fabDraggable ? fabDragGesture : nil)
                        .padding(store.fabOnLeft ? .leading : .trailing, InspectorTheme.Spacing.xl)
                        .padding(.bottom, InspectorTheme.Spacing.sm)
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
                InspectorRootView(store: store)
                    .environment(\.inspectorStore, store)
            }
    }

    // MARK: - FAB

    private var fabView: some View {
        FloatingActionButtonView(
            icon: "ladybug.fill",
            backgroundColor: InspectorTheme.Colors.fab,
            foregroundColor: InspectorTheme.Colors.fabForeground,
            size: InspectorTheme.Size.fab
        ) {
            isPresented = true
        }
        .overlay(alignment: .topTrailing) {
            if store.showErrorBadge && errorCount > 0 {
                Text("\(errorCount)")
                    .font(InspectorTheme.Typography.detail)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(InspectorTheme.Colors.error)
                    .clipShape(.capsule)
                    .offset(x: 4, y: -4)
            }
        }
    }

    private var fabDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                store.fabDragOffset = CGSize(
                    width: store.fabDragOffset.width + value.translation.width,
                    height: store.fabDragOffset.height + value.translation.height
                )
                dragOffset = .zero
            }
    }
}

// MARK: - Lifecycle (internal)

enum InspectorLifecycle {

    nonisolated(unsafe) private static var isStarted = false

    static func start(store: InspectorStore) {
        guard !isStarted else { return }
        isStarted = true

        let logger = NetworkLogger(store: store)
        InspectorURLProtocol.logger = logger
        InspectorURLProtocol.blacklistedHosts = store.blacklistedHosts
        InspectorURLProtocol.mockRules = store.mockRules
        InspectorURLProtocol.isMockingEnabled = store.isMockingEnabled

        // Swizzle URLSessionConfiguration to inject our protocol into ALL sessions
        URLSessionConfiguration.swizzleDefaultConfiguration()

        // Push notification interception
        PushNotificationInterceptor.store = store
        PushNotificationInterceptor.install()

    }

    static func stop() {
        InspectorURLProtocol.logger = nil
        URLProtocol.unregisterClass(InspectorURLProtocol.self)
        isStarted = false
    }

    /// Returns a URLSessionConfiguration with the inspector protocol registered.
    ///
    /// Use this for custom URLSession instances:
    /// ```swift
    /// let session = URLSession(configuration: InspectorLifecycle.configuration())
    /// ```
    public static func configuration(base: URLSessionConfiguration = .default) -> URLSessionConfiguration {
        let config = base
        var protocols = config.protocolClasses ?? []
        protocols.insert(InspectorURLProtocol.self, at: 0)
        config.protocolClasses = protocols
        return config
    }
}

// MARK: - Shake Gesture Detection

private struct ShakeDetectorModifier: ViewModifier {
    let enabled: Bool
    let action: () -> Void

    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        if enabled {
            content
                .background(ShakeDetectorView(action: action))
        } else {
            content
        }
    }
}

private struct ShakeDetectorView: UIViewControllerRepresentable {
    let action: () -> Void

    func makeUIViewController(context: Context) -> ShakeDetectorController {
        ShakeDetectorController(action: action)
    }

    func updateUIViewController(_ uiViewController: ShakeDetectorController, context: Context) {}
}

final class ShakeDetectorController: UIViewController {
    let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            action()
        }
    }
}

private extension View {
    func onShake(enabled: Bool, action: @escaping () -> Void) -> some View {
        modifier(ShakeDetectorModifier(enabled: enabled, action: action))
    }
}
