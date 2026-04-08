import Foundation

/// Represents a captured network request and its response.
public struct NetworkEntry: Identifiable, Codable, Sendable {

    /// Detailed timing breakdown for a network request.
    public struct TimingMetrics: Codable, Sendable {
        /// Time spent resolving the hostname.
        public let dnsLookup: TimeInterval?
        /// Time spent establishing the TCP connection.
        public let tcpConnect: TimeInterval?
        /// Time spent on the TLS handshake.
        public let tlsHandshake: TimeInterval?
        /// Time spent sending the request body.
        public let requestSent: TimeInterval?
        /// Time waiting for the first byte of the response (TTFB).
        public let waitingForResponse: TimeInterval?
        /// Time spent receiving the response body.
        public let responseReceived: TimeInterval?
        /// Total request duration from start to finish.
        public let total: TimeInterval?
    }

    /// Unique identifier for this entry.
    public var id = UUID()
    /// When the request was initiated.
    public let timestamp: Date
    /// The log type derived from the response status.
    public let type: LogType

    // MARK: - Request

    /// The full URL string of the request.
    public let requestURL: String
    /// The HTTP method (GET, POST, etc.).
    public let requestMethod: String
    /// The request headers sent with the request.
    public let requestHeaders: [String: String]
    /// The request body as a string, if any.
    public let requestBody: String?

    // MARK: - Response

    /// The HTTP status code returned by the server.
    public let responseStatusCode: Int?
    /// The response headers returned by the server.
    public let responseHeaders: [String: String]?
    /// The response body as a string, if any.
    public let responseBody: String?
    /// The error description if the request failed.
    public let responseError: String?

    // MARK: - Authentication

    /// The authorization token extracted from the request, if present.
    public let authToken: String?
    /// The type of auth token (e.g. "Bearer").
    public let authTokenType: String?
    /// The character length of the auth token.
    public let authTokenLength: Int?

    // MARK: - Metrics

    /// Total request duration in seconds.
    public let duration: TimeInterval?
    /// Size of the request body in bytes.
    public let requestSize: Int?
    /// Size of the response body in bytes.
    public let responseSize: Int?
    /// Detailed timing breakdown for this request.
    public let metrics: TimingMetrics?

    /// Number of HTTP redirects that occurred.
    public var redirectCount: Int = 0

    /// Whether this entry was served by a mock rule.
    public var isMocked: Bool = false

    /// Whether this entry is a replayed request.
    public var isReplay: Bool = false

    // MARK: - GraphQL

    /// Parsed GraphQL info, if this is a GraphQL request.
    var graphQLInfo: GraphQLInfo? {
        GraphQLParser.parse(requestBody: requestBody, requestURL: requestURL, responseBody: responseBody)
    }

    /// Whether this request is a GraphQL operation.
    public var isGraphQL: Bool {
        graphQLInfo != nil
    }

    /// Display name for the row — uses GraphQL operation name when available.
    public var displayPath: String {
        if let info = graphQLInfo, let name = info.operationName {
            return name
        }
        return requestURL.extractPath()
    }

    // MARK: - Status

    public var isSuccess: Bool {
        guard let statusCode = responseStatusCode else { return false }
        return statusCode >= 200 && statusCode < 300
    }

    /// A human-readable error message extracted from the response, if the request failed.
    public var displayError: String? {
        guard let statusCode = responseStatusCode, statusCode >= 400 else { return nil }

        if let responseBody, let data = responseBody.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let error = json["error"] as? [String: Any] {
                if let desc = error["description"] as? String { return desc }
                if let msg = error["message"] as? String { return msg }
            }
            if let message = json["message"] as? String { return message }
            if let errorMessage = json["errorMessage"] as? String { return errorMessage }
        }

        if let responseBody, !responseBody.isEmpty {
            return responseBody.count > 200 ? String(responseBody.prefix(200)) + "..." : responseBody
        }

        if let responseError, !responseError.isEmpty {
            return responseError
        }

        return "HTTP \(statusCode)"
    }

    /// Whether the response has an error status code and a non-empty body.
    public var hasErrorResponseBody: Bool {
        guard let statusCode = responseStatusCode, statusCode >= 400 else { return false }
        return responseBody != nil && !responseBody!.isEmpty
    }
}
