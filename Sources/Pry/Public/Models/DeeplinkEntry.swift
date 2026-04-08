import Foundation

/// Represents a deeplink or universal link received by the app.
public struct DeeplinkEntry: Identifiable, Codable, Sendable {
    /// Unique identifier for this entry.
    public var id = UUID()
    /// When the deeplink was received.
    public let timestamp: Date
    /// The full URL string.
    public let url: String
    /// The URL scheme (e.g. "myapp" or "https").
    public let scheme: String?
    /// The host component of the URL.
    public let host: String?
    /// The path component of the URL.
    public let path: String
    /// The individual path segments, excluding "/".
    public let pathComponents: [String]
    /// The parsed query parameters.
    public let queryParameters: [QueryParameter]
    /// The URL fragment (after #), if any.
    public let fragment: String?

    /// The scheme and host combined (e.g. "myapp://home").
    public var schemeAndHost: String {
        let scheme = scheme ?? ""
        let host = host ?? ""
        if scheme.isEmpty && host.isEmpty { return url }
        return "\(scheme)://\(host)"
    }

    /// A single URL query parameter (name=value pair).
    public struct QueryParameter: Identifiable, Codable, Sendable {
        /// Unique identifier for this parameter.
        public var id = UUID()
        /// The parameter name.
        public let name: String
        /// The parameter value, if present.
        public let value: String?
    }
}

// MARK: - Preview Mocks

