import Foundation

/// Represents a captured network request and its response.
public struct NetworkEntry: Identifiable, Codable, Sendable {
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

