import Foundation

/// Defines a mock response rule that intercepts matching network requests.
///
/// When a request matches the `urlPattern` (and optionally the `method`),
/// the inspector returns the mock response instead of hitting the network.
public struct MockRule: Identifiable, Codable, Sendable {
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

    // MARK: - Response

    /// HTTP status code to return.
    public var statusCode: Int

    /// Response body (JSON, text, etc.).
    public var responseBody: String?

    /// Response headers.
    public var responseHeaders: [String: String]

    /// Simulated delay in seconds before returning the response.
    public var delay: TimeInterval

    /// Creates a new mock rule.
    /// - Parameters:
    ///   - name: A human-readable name for the rule.
    ///   - urlPattern: Substring to match against request URLs.
    ///   - method: HTTP method to match, or `nil` for any method.
    ///   - statusCode: HTTP status code to return. Defaults to 200.
    ///   - responseBody: The response body string to return.
    ///   - responseHeaders: Headers to include in the mock response.
    ///   - delay: Simulated delay in seconds before returning the response.
    public init(
        name: String = "",
        urlPattern: String = "",
        method: String? = nil,
        statusCode: Int = 200,
        responseBody: String? = nil,
        responseHeaders: [String: String] = ["Content-Type": "application/json"],
        delay: TimeInterval = 0
    ) {
        self.name = name
        self.urlPattern = urlPattern
        self.method = method
        self.statusCode = statusCode
        self.responseBody = responseBody
        self.responseHeaders = responseHeaders
        self.delay = delay
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
