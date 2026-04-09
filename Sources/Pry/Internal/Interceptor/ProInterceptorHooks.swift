import Foundation

// MARK: - Types exposed to PryPro

/// A synthesized response that replaces a real network round trip.
/// Installed via ``PryHooks/mockResponseFor`` by PryPro's mock engine.
@_spi(PryPro) public struct ProMockResponse: Sendable {
    @_spi(PryPro) public let statusCode: Int
    @_spi(PryPro) public let headers: [String: String]
    @_spi(PryPro) public let body: String?
    @_spi(PryPro) public let delay: TimeInterval

    @_spi(PryPro) public init(statusCode: Int, headers: [String: String], body: String?, delay: TimeInterval) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.delay = delay
    }
}

/// Behavior configuration for simulating degraded network conditions.
@_spi(PryPro) public struct ProThrottleConfig: Sendable {
    @_spi(PryPro) public let delay: TimeInterval
    @_spi(PryPro) public let failureRate: Double
    @_spi(PryPro) public let isOffline: Bool

    @_spi(PryPro) public init(delay: TimeInterval, failureRate: Double, isOffline: Bool) {
        self.delay = delay
        self.failureRate = failureRate
        self.isOffline = isOffline
    }

    @_spi(PryPro) public static let none = ProThrottleConfig(delay: 0, failureRate: 0, isOffline: false)

    @_spi(PryPro) public var isNoThrottle: Bool {
        delay == 0 && failureRate == 0 && !isOffline
    }
}

/// Result of a Pro request breakpoint hook.
@_spi(PryPro) public enum ProRequestBreakpointResult: Sendable {
    case send(URLRequest)
    case cancel
}

/// Result of a Pro response breakpoint hook.
@_spi(PryPro) public enum ProResponseBreakpointResult: Sendable {
    case sendAsIs
    case sendModified(statusCode: Int, headers: [String: String], body: String?)
    case cancel
}

// MARK: - Storage

/// Closure-based extension surface that `PryPro` uses to drive the Free
/// interceptor without introducing a reverse dependency.
///
/// Every hook defaults to `nil`. A Free-only build (no PryPro linked)
/// behaves as if throttle is `.none`, no mocks match, no breakpoints pause,
/// and the interceptor does pure passthrough.
///
/// `PryPro` installs these closures during its initialization; the closures
/// capture PryPro's own `@Observable` store so UI changes reach the
/// interceptor thread without any shared state living in Free.
@_spi(PryPro) public enum PryInterceptorHooks {

    // MARK: Throttle

    @_spi(PryPro) public static var throttle: (@Sendable () -> ProThrottleConfig)? {
        get { storage.lock.withLock { storage.throttle } }
        set { storage.lock.withLock { storage.throttle = newValue } }
    }

    // MARK: Mocks

    @_spi(PryPro) public static var mockResponseFor: (@Sendable (URLRequest) -> ProMockResponse?)? {
        get { storage.lock.withLock { storage.mockResponseFor } }
        set { storage.lock.withLock { storage.mockResponseFor = newValue } }
    }

    // MARK: Breakpoints

    /// Pauses a request before it reaches the network. Returns `nil` if no
    /// breakpoint matches. Otherwise the returned closure is an async waiter
    /// that resolves to the user's decision (send modified, or cancel).
    @_spi(PryPro) public static var pauseRequestIfNeeded: (@Sendable (URLRequest) -> (@Sendable () async -> ProRequestBreakpointResult)?)? {
        get { storage.lock.withLock { storage.pauseRequestIfNeeded } }
        set { storage.lock.withLock { storage.pauseRequestIfNeeded = newValue } }
    }

    /// Returns true if the interceptor should buffer the response and pause
    /// before delivering it to the client. When this returns true the
    /// interceptor will call ``pauseResponse`` once it has the response.
    @_spi(PryPro) public static var shouldPauseResponse: (@Sendable (URLRequest) -> Bool)? {
        get { storage.lock.withLock { storage.shouldPauseResponse } }
        set { storage.lock.withLock { storage.shouldPauseResponse = newValue } }
    }

    /// Pauses an already received response and awaits the user's decision.
    @_spi(PryPro) public static var pauseResponse: (@Sendable (URLRequest, Int, [String: String], String?) async -> ProResponseBreakpointResult)? {
        get { storage.lock.withLock { storage.pauseResponse } }
        set { storage.lock.withLock { storage.pauseResponse = newValue } }
    }

    /// Timeout for the breakpoint waiter. PryPro sets this to a sensible
    /// default; Free never uses it since no waiter is installed.
    @_spi(PryPro) public static var breakpointTimeout: TimeInterval {
        get { storage.lock.withLock { storage.breakpointTimeout } }
        set { storage.lock.withLock { storage.breakpointTimeout = newValue } }
    }

    // MARK: - Internal Storage

    private static let storage = Storage()

    private final class Storage: @unchecked Sendable {
        let lock = NSLock()
        var throttle: (@Sendable () -> ProThrottleConfig)?
        var mockResponseFor: (@Sendable (URLRequest) -> ProMockResponse?)?
        var pauseRequestIfNeeded: (@Sendable (URLRequest) -> (@Sendable () async -> ProRequestBreakpointResult)?)?
        var shouldPauseResponse: (@Sendable (URLRequest) -> Bool)?
        var pauseResponse: (@Sendable (URLRequest, Int, [String: String], String?) async -> ProResponseBreakpointResult)?
        var breakpointTimeout: TimeInterval = 120
    }
}
