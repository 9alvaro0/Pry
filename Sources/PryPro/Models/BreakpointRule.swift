import Foundation

/// Defines a breakpoint that pauses matching requests for inspection/editing.
public struct BreakpointRule: Identifiable, Codable, Sendable {
    /// Unique identifier for this rule.
    public var id = UUID()
    /// Whether this rule is currently active.
    public var isEnabled: Bool = true
    /// A human-readable name for this rule.
    public var name: String

    // MARK: - Matching

    /// URL pattern to match against (uses `contains` matching).
    public var urlPattern: String

    /// HTTP method to match. `nil` matches any method.
    public var method: String?

    // MARK: - Type

    /// When to pause: before sending (request), after receiving (response), or both.
    public var pauseOn: PauseType

    /// Determines when the breakpoint pauses execution.
    public enum PauseType: String, Codable, CaseIterable, Sendable {
        /// Pause before the request is sent.
        case request = "Request"
        /// Pause after the response is received.
        case response = "Response"
        /// Pause on both request and response.
        case both = "Both"
    }

    /// Creates a new breakpoint rule.
    /// - Parameters:
    ///   - name: A human-readable name for the rule.
    ///   - urlPattern: Substring to match against request URLs.
    ///   - method: HTTP method to match, or `nil` for any method.
    ///   - pauseOn: When to pause execution. Defaults to `.request`.
    public init(
        name: String = "",
        urlPattern: String = "",
        method: String? = nil,
        pauseOn: PauseType = .request
    ) {
        self.name = name
        self.urlPattern = urlPattern
        self.method = method
        self.pauseOn = pauseOn
    }

    /// Checks if this rule matches the given request.
    func matches(_ request: URLRequest) -> Bool {
        guard isEnabled else { return false }
        guard !urlPattern.isEmpty else { return false }

        let url = request.url?.absoluteString ?? ""
        guard url.localizedCaseInsensitiveContains(urlPattern) else { return false }

        if let method, !method.isEmpty {
            guard request.httpMethod?.uppercased() == method.uppercased() else { return false }
        }

        return true
    }
}
