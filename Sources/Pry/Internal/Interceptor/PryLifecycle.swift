import Foundation

/// Manages the inspector's lifecycle: starting/stopping interception.
enum PryLifecycle {

    nonisolated(unsafe) private static var isStarted = false

    static func start(store: PryStore) {
        guard !isStarted else { return }
        isStarted = true

        let logger = NetworkLogger(store: store)
        let config = PryConfig.shared
        config.logger = logger
        config.blacklistedHosts = store.blacklistedHosts

        // Swizzle URLSessionConfiguration to inject our protocol into ALL sessions
        URLSessionConfiguration.swizzleDefaultConfiguration()

        // Push notification interception
        PushNotificationInterceptor.store = store
        PushNotificationInterceptor.install()
    }

    static func stop() {
        PryConfig.shared.logger = nil
        URLProtocol.unregisterClass(PryURLProtocol.self)
        isStarted = false
    }

    /// Returns a URLSessionConfiguration with the inspector protocol registered.
    ///
    /// Use this for custom URLSession instances:
    /// ```swift
    /// let session = URLSession(configuration: PryLifecycle.configuration())
    /// ```
    public static func configuration(base: URLSessionConfiguration = .default) -> URLSessionConfiguration {
        let config = base
        var protocols = config.protocolClasses ?? []
        protocols.insert(PryURLProtocol.self, at: 0)
        config.protocolClasses = protocols
        return config
    }
}
