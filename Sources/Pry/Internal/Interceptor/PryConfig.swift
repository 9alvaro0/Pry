import Foundation

/// Thread-safe container for Free interceptor configuration.
///
/// Pro-only state (mock rules, breakpoint rules, throttle) lives in
/// `PryInterceptorHooks` as closures installed by PryPro. Keeping this
/// container minimal lets the Free SDK ship without any reverse
/// dependency on the Pro feature set.
///
/// Accessed from network threads (read) and main thread (write).
final class PryConfig: @unchecked Sendable {
    static let shared = PryConfig()

    private let lock = NSLock()
    private var _logger: NetworkLogger?
    private var _blacklistedHosts: Set<String> = []

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
}
