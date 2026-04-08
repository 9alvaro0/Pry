import Foundation

/// Defines a breakpoint that pauses matching requests for inspection/editing.
public struct BreakpointRule: Identifiable, Codable, Sendable {
    public var id = UUID()
    public var isEnabled: Bool = true
    public var name: String

    // MARK: - Matching

    /// URL pattern to match against (uses `contains` matching).
    public var urlPattern: String

    /// HTTP method to match. `nil` matches any method.
    public var method: String?

    // MARK: - Type

    /// When to pause: before sending (request), after receiving (response), or both.
    public var pauseOn: PauseType

    public enum PauseType: String, Codable, CaseIterable, Sendable {
        case request = "Request"
        case response = "Response"
        case both = "Both"
    }

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
