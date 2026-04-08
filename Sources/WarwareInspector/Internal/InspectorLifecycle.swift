import Foundation

/// Manages the inspector's lifecycle: starting/stopping interception.
enum InspectorLifecycle {

    nonisolated(unsafe) private static var isStarted = false

    static func start(store: InspectorStore) {
        guard !isStarted else { return }
        isStarted = true

        let logger = NetworkLogger(store: store)
        let config = InterceptorConfig.shared
        config.logger = logger
        config.blacklistedHosts = store.blacklistedHosts
        config.mockRules = store.mockRules
        config.isMockingEnabled = store.isMockingEnabled

        // Swizzle URLSessionConfiguration to inject our protocol into ALL sessions
        URLSessionConfiguration.swizzleDefaultConfiguration()

        // Push notification interception
        PushNotificationInterceptor.store = store
        PushNotificationInterceptor.install()
    }

    static func stop() {
        InterceptorConfig.shared.logger = nil
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
