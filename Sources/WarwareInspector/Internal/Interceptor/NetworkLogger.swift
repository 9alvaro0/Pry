import Foundation

/// Captures and logs network requests/responses into the InspectorStore.
final class NetworkLogger: @unchecked Sendable {

    private weak var store: InspectorStore?
    private var pendingRequests: [UUID: NetworkEntry] = [:]
    private let queue = DispatchQueue(label: "WarwareInspector.NetworkLogger", qos: .utility)

    init(store: InspectorStore) {
        self.store = store
    }

    // MARK: - Logging

    /// Logs the start of a request. Returns a request ID to correlate with the response.
    @discardableResult
    func logRequest(url: String, method: String, headers: [String: String], body: Data?) -> UUID {
        let requestID = UUID()
        let timestamp = Date()

        let authHeader = headers["Authorization"]
        let authTokenType = authHeader.flatMap { extractAuthType($0) }
        // Extract just the token value (strip "Bearer ", "Basic ", etc.)
        let authToken = authHeader.flatMap { extractTokenValue($0) }
        let authTokenLength = authToken?.count

        let entry = NetworkEntry(
            timestamp: timestamp,
            type: .network,
            requestURL: url,
            requestMethod: method,
            requestHeaders: headers,
            requestBody: bodyToString(body),
            responseStatusCode: nil,
            responseHeaders: nil,
            responseBody: nil,
            responseError: nil,
            authToken: authToken,
            authTokenType: authTokenType,
            authTokenLength: authTokenLength,
            duration: nil,
            requestSize: body?.count,
            responseSize: nil
        )

        queue.async { [weak self] in
            self?.pendingRequests[requestID] = entry
        }

        // Immediately show as pending in the UI
        Task { @MainActor [store] in
            store?.addNetworkEntry(entry)
        }

        return requestID
    }

    func logResponse(
        requestID: UUID,
        statusCode: Int,
        headers: [String: String],
        body: Data?,
        error: Error?,
        duration: TimeInterval
    ) {
        // Skip cancelled requests
        if let nsError = error as NSError?,
           nsError.domain == NSURLErrorDomain,
           nsError.code == NSURLErrorCancelled {
            queue.async { [weak self] in
                self?.pendingRequests.removeValue(forKey: requestID)
            }
            return
        }

        queue.async { [weak self] in
            guard let self else { return }

            let pending = self.pendingRequests.removeValue(forKey: requestID)

            let entry = NetworkEntry(
                id: pending?.id ?? UUID(),
                timestamp: pending?.timestamp ?? Date(),
                type: .network,
                requestURL: pending?.requestURL ?? "Unknown",
                requestMethod: pending?.requestMethod ?? "GET",
                requestHeaders: pending?.requestHeaders ?? [:],
                requestBody: pending?.requestBody,
                responseStatusCode: statusCode == 0 ? nil : statusCode,
                responseHeaders: headers.isEmpty ? nil : headers,
                responseBody: self.bodyToString(body),
                responseError: error?.localizedDescription,
                authToken: pending?.authToken,
                authTokenType: pending?.authTokenType,
                authTokenLength: pending?.authTokenLength,
                duration: duration,
                requestSize: pending?.requestSize,
                responseSize: body?.count
            )

            Task { @MainActor in
                self.store?.updateOrAddNetworkEntry(entry)
            }
        }
    }

    // MARK: - Helpers

    private func bodyToString(_ data: Data?) -> String? {
        guard let data else { return nil }

        let maxSize = 1_000_000
        let limitedData = data.count > maxSize ? data.prefix(maxSize) : data

        if let jsonObject = try? JSONSerialization.jsonObject(with: limitedData, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return data.count > maxSize
                ? prettyString + "\n\n[Truncated... Total size: \(data.count) bytes]"
                : prettyString
        }

        if let rawString = String(data: limitedData, encoding: .utf8) {
            return data.count > maxSize
                ? rawString + "\n\n[Truncated... Total size: \(data.count) bytes]"
                : rawString
        }

        return "[Binary data: \(data.count) bytes]"
    }

    private func extractAuthType(_ authHeader: String) -> String {
        if authHeader.hasPrefix("Bearer ") { return "Bearer Token" }
        if authHeader.hasPrefix("Basic ") { return "Basic Auth" }
        if authHeader.hasPrefix("Digest ") { return "Digest Auth" }
        return "Custom Auth"
    }

    private func extractTokenValue(_ authHeader: String) -> String? {
        let prefixes = ["Bearer ", "Basic ", "Digest "]
        for prefix in prefixes {
            if authHeader.hasPrefix(prefix) {
                return String(authHeader.dropFirst(prefix.count))
            }
        }
        return authHeader
    }
}
