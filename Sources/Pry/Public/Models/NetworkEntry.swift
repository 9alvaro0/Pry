import Foundation

/// Represents a captured network request and its response.
public struct NetworkEntry: Identifiable, Codable, Sendable {

    public struct TimingMetrics: Codable, Sendable {
        public let dnsLookup: TimeInterval?
        public let tcpConnect: TimeInterval?
        public let tlsHandshake: TimeInterval?
        public let requestSent: TimeInterval?
        public let waitingForResponse: TimeInterval? // TTFB
        public let responseReceived: TimeInterval?
        public let total: TimeInterval?
    }

    public var id = UUID()
    public let timestamp: Date
    public let type: LogType

    // Request
    public let requestURL: String
    public let requestMethod: String
    public let requestHeaders: [String: String]
    public let requestBody: String?

    // Response
    public let responseStatusCode: Int?
    public let responseHeaders: [String: String]?
    public let responseBody: String?
    public let responseError: String?

    // Authentication
    public let authToken: String?
    public let authTokenType: String?
    public let authTokenLength: Int?

    // Metrics
    public let duration: TimeInterval?
    public let requestSize: Int?
    public let responseSize: Int?
    public let metrics: TimingMetrics?

    // Redirects
    public var redirectCount: Int = 0

    // Mock
    public var isMocked: Bool = false

    // Replay
    public var isReplay: Bool = false

    // MARK: - GraphQL

    /// Parsed GraphQL info, if this is a GraphQL request.
    var graphQLInfo: GraphQLInfo? {
        GraphQLParser.parse(requestBody: requestBody, requestURL: requestURL, responseBody: responseBody)
    }

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

    public var hasErrorResponseBody: Bool {
        guard let statusCode = responseStatusCode, statusCode >= 400 else { return false }
        return responseBody != nil && !responseBody!.isEmpty
    }
}
