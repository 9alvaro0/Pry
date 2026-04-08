import Foundation

/// Represents a paused request waiting for user action.
@Observable @MainActor
final class PausedRequest: Identifiable {
    let id = UUID()
    let originalRequest: URLRequest
    let rule: BreakpointRule
    let timestamp = Date()

    // Editable fields
    var url: String
    var method: String
    var headers: [String: String]
    var body: String

    // For response breakpoints
    var isResponseBreakpoint: Bool = false
    var responseStatusCode: Int?
    var responseHeaders: [String: String]?
    var responseBody: String?

    init(request: URLRequest, rule: BreakpointRule) {
        self.originalRequest = request
        self.rule = rule
        self.url = request.url?.absoluteString ?? ""
        self.method = request.httpMethod ?? "GET"
        self.headers = request.allHTTPHeaderFields ?? [:]
        self.body = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    /// Build the modified URLRequest from edited fields.
    func buildModifiedRequest() -> URLRequest {
        var request = URLRequest(url: URL(string: url) ?? originalRequest.url!)
        request.httpMethod = method

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if !body.isEmpty {
            request.httpBody = body.data(using: .utf8)
        }

        return request
    }
}

/// Coordinates breakpoint pauses between the network thread and the UI.
/// The interceptor calls `pauseRequest()` which suspends the network thread.
/// The UI calls `resumeRequest()` or `cancelRequest()` to unblock it.
@MainActor
final class BreakpointManager: @unchecked Sendable {

    static let shared = BreakpointManager()

    /// The currently paused request (observed by the UI).
    @Observable
    final class State {
        var pausedRequest: PausedRequest?
    }

    let state = State()

    // Continuation that the network thread is waiting on
    private var continuation: CheckedContinuation<BreakpointAction, Never>?

    enum BreakpointAction: Sendable {
        case send(URLRequest)     // Send with (possibly modified) request
        case cancel               // Cancel the request entirely
    }

    private init() {}

    // MARK: - Called from URLProtocol thread (suspends until user acts)

    /// Pauses a request for user inspection. Called from the network thread.
    /// Returns the action the user chose (send modified or cancel).
    nonisolated func pauseRequest(_ request: URLRequest, rule: BreakpointRule) async -> BreakpointAction {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.continuation = continuation
                self.state.pausedRequest = PausedRequest(request: request, rule: rule)
            }
        }
    }

    /// Pauses after receiving a response, allowing the user to modify it.
    nonisolated func pauseResponse(
        request: URLRequest,
        rule: BreakpointRule,
        statusCode: Int,
        headers: [String: String],
        body: String?
    ) async -> BreakpointAction {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.continuation = continuation
                let paused = PausedRequest(request: request, rule: rule)
                paused.isResponseBreakpoint = true
                paused.responseStatusCode = statusCode
                paused.responseHeaders = headers
                paused.responseBody = body
                self.state.pausedRequest = paused
            }
        }
    }

    // MARK: - Called from UI (resumes the network thread)

    /// User tapped "Send" — resume with the (possibly modified) request.
    func resumeRequest() {
        guard let paused = state.pausedRequest else { return }
        let modified = paused.buildModifiedRequest()
        state.pausedRequest = nil
        continuation?.resume(returning: .send(modified))
        continuation = nil
    }

    /// User tapped "Cancel" — drop the request entirely.
    func cancelRequest() {
        state.pausedRequest = nil
        continuation?.resume(returning: .cancel)
        continuation = nil
    }
}
