import Foundation
import Observation
@_exported import Pry

/// Observable store that holds Pro-only state: mock rules, breakpoint rules
/// and network throttle configuration.
///
/// `PryProStore` wraps the Free ``PryStore`` so consumers of the Pro SDK
/// create a single store and get everything:
///
/// ```swift
/// @State private var store = PryProStore()
///
/// var body: some Scene {
///     WindowGroup {
///         ContentView().pryPro(store: store)
///     }
/// }
/// ```
///
/// All mutations performed on this store update ``PryInterceptorHooks`` on
/// the network thread automatically, so the interceptor sees fresh state
/// without any manual sync.
@MainActor
@Observable
public final class PryProStore {

    /// The inner Free store. Use this when a plain ``PryStore`` is expected.
    public let store: PryStore

    // MARK: - Mock Rules

    public private(set) var mockRules: [MockRule] = [] {
        didSet { refreshInterceptorHooks() }
    }

    public var isMockingEnabled: Bool {
        mockRules.contains(where: \.isEnabled)
    }

    public func addMockRule(_ rule: MockRule) {
        mockRules.append(rule)
    }

    public func removeMockRule(_ id: UUID) {
        mockRules.removeAll { $0.id == id }
    }

    public func toggleMockRule(_ id: UUID) {
        guard let index = mockRules.firstIndex(where: { $0.id == id }) else { return }
        mockRules[index].isEnabled.toggle()
    }

    // MARK: - Breakpoint Rules

    public private(set) var breakpointRules: [BreakpointRule] = [] {
        didSet { refreshInterceptorHooks() }
    }

    public var isBreakpointEnabled: Bool {
        breakpointRules.contains(where: \.isEnabled)
    }

    public func addBreakpointRule(_ rule: BreakpointRule) {
        breakpointRules.append(rule)
    }

    public func removeBreakpointRule(_ id: UUID) {
        breakpointRules.removeAll { $0.id == id }
    }

    public func toggleBreakpointRule(_ id: UUID) {
        guard let index = breakpointRules.firstIndex(where: { $0.id == id }) else { return }
        breakpointRules[index].isEnabled.toggle()
    }

    // MARK: - Network Throttle

    public var networkThrottle: NetworkThrottle = .none {
        didSet { refreshInterceptorHooks() }
    }

    // MARK: - Init

    public init(store: PryStore = PryStore()) {
        self.store = store
        refreshInterceptorHooks()
    }

    #if DEBUG
    /// Preview factory with realistic data across all Pro features.
    public static var preview: PryProStore {
        let pro = PryProStore(store: .preview)
        pro.mockRules = [.mockUsersSuccess, .mockCartError]
        return pro
    }
    #endif

    // MARK: - Interceptor Hook Sync

    /// Pushes the current state into the Free interceptor hooks so the network
    /// thread sees the latest rules without any additional plumbing.
    private func refreshInterceptorHooks() {
        let snapshotMocks = mockRules
        let snapshotBreakpoints = breakpointRules
        let snapshotThrottle = networkThrottle

        // Mock response lookup
        PryInterceptorHooks.mockResponseFor = { request in
            guard snapshotMocks.contains(where: \.isEnabled) else { return nil }
            guard let rule = snapshotMocks.first(where: { $0.matches(request) }) else { return nil }
            return ProMockResponse(
                statusCode: rule.statusCode,
                headers: rule.responseHeaders,
                body: rule.responseBody,
                delay: rule.delay
            )
        }

        // Throttle
        PryInterceptorHooks.throttle = {
            ProThrottleConfig(
                delay: snapshotThrottle.delay,
                failureRate: snapshotThrottle.failureRate,
                isOffline: snapshotThrottle == .offline
            )
        }

        // Request breakpoint
        PryInterceptorHooks.pauseRequestIfNeeded = { request in
            guard snapshotBreakpoints.contains(where: \.isEnabled) else { return nil }
            guard let rule = snapshotBreakpoints.first(where: { $0.matches(request) }),
                  rule.pauseOn == .request || rule.pauseOn == .both else { return nil }
            return { @Sendable in
                let result = await BreakpointManager.shared.pauseRequest(request, rule: rule)
                switch result {
                case .send(let modified): return .send(modified)
                case .cancel, .sendResponse: return .cancel
                }
            }
        }

        // Response breakpoint
        PryInterceptorHooks.shouldPauseResponse = { request in
            guard snapshotBreakpoints.contains(where: \.isEnabled) else { return false }
            guard let rule = snapshotBreakpoints.first(where: { $0.matches(request) }) else { return false }
            return rule.pauseOn == .response || rule.pauseOn == .both
        }

        PryInterceptorHooks.pauseResponse = { request, statusCode, headers, body in
            guard let rule = snapshotBreakpoints.first(where: { $0.matches(request) }) else {
                return .sendAsIs
            }
            let result = await BreakpointManager.shared.pauseResponse(
                request: request,
                rule: rule,
                statusCode: statusCode,
                headers: headers,
                body: body
            )
            switch result {
            case .sendResponse(let status, let headers, let body):
                return .sendModified(statusCode: status, headers: headers, body: body)
            case .send, .cancel:
                return .cancel
            }
        }
    }
}
