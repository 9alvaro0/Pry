import Foundation

/// Represents a deeplink or universal link received by the app.
public struct DeeplinkEntry: Identifiable, Codable, Sendable {
    public var id = UUID()
    public let timestamp: Date
    public let url: String
    public let scheme: String?
    public let host: String?
    public let path: String
    public let pathComponents: [String]
    public let queryParameters: [QueryParameter]
    public let fragment: String?

    public var schemeAndHost: String {
        let scheme = scheme ?? ""
        let host = host ?? ""
        if scheme.isEmpty && host.isEmpty { return url }
        return "\(scheme)://\(host)"
    }

    public struct QueryParameter: Identifiable, Codable, Sendable {
        public var id = UUID()
        public let name: String
        public let value: String?
    }
}

// MARK: - Preview Mocks

