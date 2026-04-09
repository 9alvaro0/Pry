import Foundation

/// A single HTTP redirect in a request's redirect chain.
///
/// Captured when URLSession receives a 3xx response and follows the `Location` header.
public struct RedirectHop: Identifiable, Codable, Sendable, Hashable {
    public var id = UUID()

    /// The URL that returned the redirect response.
    public let fromURL: String

    /// The HTTP status code of the redirect response (301, 302, 303, 307, 308).
    public let statusCode: Int

    /// The `Location` the client is being redirected to.
    public let toURL: String
}
