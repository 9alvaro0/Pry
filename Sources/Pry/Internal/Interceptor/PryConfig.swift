import Foundation

/// Thread-safe container for all interceptor configuration.
/// Accessed from network threads (read) and main thread (write).
final class PryConfig: @unchecked Sendable {
    static let shared = PryConfig()

    private let lock = NSLock()
    private var _logger: NetworkLogger?
    private var _blacklistedHosts: Set<String> = []
    private var _mockRules: [MockRule] = []
    private var _isMockingEnabled: Bool = false
    private var _throttle: NetworkThrottle = .none
    private var _breakpointRules: [BreakpointRule] = []
    private var _isBreakpointEnabled: Bool = false

    private init() {}

    // MARK: - Thread-safe accessors

    var logger: NetworkLogger? {
        get { lock.withLock { _logger } }
        set { lock.withLock { _logger = newValue } }
    }

    var blacklistedHosts: Set<String> {
        get { lock.withLock { _blacklistedHosts } }
        set { lock.withLock { _blacklistedHosts = newValue } }
    }

    var mockRules: [MockRule] {
        get { lock.withLock { _mockRules } }
        set { lock.withLock { _mockRules = newValue } }
    }

    var isMockingEnabled: Bool {
        get { lock.withLock { _isMockingEnabled } }
        set { lock.withLock { _isMockingEnabled = newValue } }
    }

    var throttle: NetworkThrottle {
        get { lock.withLock { _throttle } }
        set { lock.withLock { _throttle = newValue } }
    }

    var breakpointRules: [BreakpointRule] {
        get { lock.withLock { _breakpointRules } }
        set { lock.withLock { _breakpointRules = newValue } }
    }

    var isBreakpointEnabled: Bool {
        get { lock.withLock { _isBreakpointEnabled } }
        set { lock.withLock { _isBreakpointEnabled = newValue } }
    }

    /// Finds the first enabled mock rule matching the given request.
    func findMatchingMock(for request: URLRequest) -> MockRule? {
        lock.withLock { _mockRules.first { $0.matches(request) } }
    }

    /// Finds the first enabled breakpoint rule matching the given request.
    func findMatchingBreakpoint(for request: URLRequest) -> BreakpointRule? {
        lock.withLock { _breakpointRules.first { $0.matches(request) } }
    }
}
