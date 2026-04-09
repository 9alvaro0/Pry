import Foundation

// MARK: - Types exposed to PryPro

/// A synthesized response that replaces a real network round trip.
/// Installed via ``PryHooks/mockResponseFor`` by PryPro's mock engine.
package struct ProMockResponse: Sendable {
    package let statusCode: Int
    package let headers: [String: String]
    package let body: String?
    package let delay: TimeInterval

    package init(statusCode: Int, headers: [String: String], body: String?, delay: TimeInterval) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.delay = delay
    }
}

/// Behavior configuration for simulating degraded network conditions.
package struct ProThrottleConfig: Sendable {
    package let delay: TimeInterval
    package let failureRate: Double
    package let isOffline: Bool

    package init(delay: TimeInterval, failureRate: Double, isOffline: Bool) {
        self.delay = delay
        self.failureRate = failureRate
        self.isOffline = isOffline
    }

    package static let none = ProThrottleConfig(delay: 0, failureRate: 0, isOffline: false)

    package var isNoThrottle: Bool {
        delay == 0 && failureRate == 0 && !isOffline
    }
}

/// Result of a Pro request breakpoint hook.
package enum ProRequestBreakpointResult: Sendable {
    case send(URLRequest)
    case cancel
}

/// Result of a Pro response breakpoint hook.
package enum ProResponseBreakpointResult: Sendable {
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
package enum PryInterceptorHooks {

    // MARK: Throttle

    package static var throttle: (@Sendable () -> ProThrottleConfig)? {
        get { storage.lock.withLock { storage.throttle } }
        set { storage.lock.withLock { storage.throttle = newValue } }
    }

    // MARK: Mocks

    package static var mockResponseFor: (@Sendable (URLRequest) -> ProMockResponse?)? {
        get { storage.lock.withLock { storage.mockResponseFor } }
        set { storage.lock.withLock { storage.mockResponseFor = newValue } }
    }

    // MARK: Breakpoints

    /// Pauses a request before it reaches the network. Returns `nil` if no
    /// breakpoint matches. Otherwise the returned closure is an async waiter
    /// that resolves to the user's decision (send modified, or cancel).
    package static var pauseRequestIfNeeded: (@Sendable (URLRequest) -> (@Sendable () async -> ProRequestBreakpointResult)?)? {
        get { storage.lock.withLock { storage.pauseRequestIfNeeded } }
        set { storage.lock.withLock { storage.pauseRequestIfNeeded = newValue } }
    }

    /// Returns true if the interceptor should buffer the response and pause
    /// before delivering it to the client. When this returns true the
    /// interceptor will call ``pauseResponse`` once it has the response.
    package static var shouldPauseResponse: (@Sendable (URLRequest) -> Bool)? {
        get { storage.lock.withLock { storage.shouldPauseResponse } }
        set { storage.lock.withLock { storage.shouldPauseResponse = newValue } }
    }

    /// Pauses an already received response and awaits the user's decision.
    package static var pauseResponse: (@Sendable (URLRequest, Int, [String: String], String?) async -> ProResponseBreakpointResult)? {
        get { storage.lock.withLock { storage.pauseResponse } }
        set { storage.lock.withLock { storage.pauseResponse = newValue } }
    }

    /// Timeout for the breakpoint waiter. PryPro sets this to a sensible
    /// default; Free never uses it since no waiter is installed.
    package static var breakpointTimeout: TimeInterval {
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
