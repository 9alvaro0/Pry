import Foundation

/// Defines a mock response rule that intercepts matching network requests.
///
/// When a request matches the `urlPattern` (and optionally the `method`),
/// the inspector returns the mock response instead of hitting the network.
public struct MockRule: Identifiable, Codable, Sendable {
    public var id = UUID()
    public var isEnabled: Bool = true
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
