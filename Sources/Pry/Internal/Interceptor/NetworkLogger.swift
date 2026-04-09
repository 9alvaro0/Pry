import Foundation

/// Captures and logs network requests/responses into the PryStore.
final class NetworkLogger: @unchecked Sendable {

    private weak var store: PryStore?
    private var pendingRequests: [UUID: NetworkEntry] = [:]
    private let queue = DispatchQueue(label: "Pry.NetworkLogger", qos: .utility)

    init(store: PryStore) {
        self.store = store
    }

    // MARK: - Logging

    /// Logs the start of a request. Returns a request ID to correlate with the response.
    @discardableResult
    func logRequest(url: String, method: String, headers: [String: String], body: Data?) -> UUID {
        let requestID = UUID()
        let timestamp = Date()

        // Detect replay requests and strip the internal header
        let isReplay = headers["X-Pry-Replay"] != nil
        var cleanHeaders = headers
        cleanHeaders.removeValue(forKey: "X-Pry-Replay")

        let authHeader = cleanHeaders["Authorization"]
        let authTokenType = authHeader.flatMap { extractAuthType($0) }
        let authToken = authHeader.flatMap { extractTokenValue($0) }
        let authTokenLength = authToken?.count

        var entry = NetworkEntry(
            timestamp: timestamp,
            type: .network,
            requestURL: url,
            requestMethod: method,
            requestHeaders: cleanHeaders,
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
            responseSize: nil,
            metrics: nil
        )
        entry.isReplay = isReplay

        queue.async { [weak self] in
            self?.pendingRequests[requestID] = entry
        }

        return requestID
    }

    func logResponse(
        requestID: UUID,
        statusCode: Int,
        headers: [String: String],
        body: Data?,
        error: Error?,
        duration: TimeInterval,
        taskMetrics: URLSessionTaskMetrics?,
        redirectCount: Int = 0,
        redirects: [RedirectHop] = []
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

            let metrics: NetworkEntry.TimingMetrics? = {
                guard let tm = taskMetrics,
                      let transaction = tm.transactionMetrics.last else { return nil }

                let dns = transaction.domainLookupEndDate.flatMap { end in
                    transaction.domainLookupStartDate.map { start in end.timeIntervalSince(start) }
                }
                let tcp = transaction.connectEndDate.flatMap { end in
                    transaction.connectStartDate.map { start in end.timeIntervalSince(start) }
                }
                let tls = transaction.secureConnectionEndDate.flatMap { end in
                    transaction.secureConnectionStartDate.map { start in end.timeIntervalSince(start) }
                }
                let reqSent = transaction.requestEndDate.flatMap { end in
                    transaction.requestStartDate.map { start in end.timeIntervalSince(start) }
                }
                let waiting = transaction.responseStartDate.flatMap { end in
                    transaction.requestEndDate.map { start in end.timeIntervalSince(start) }
                }
                let respReceived = transaction.responseEndDate.flatMap { end in
                    transaction.responseStartDate.map { start in end.timeIntervalSince(start) }
                }

                return NetworkEntry.TimingMetrics(
                    dnsLookup: dns,
                    tcpConnect: tcp,
                    tlsHandshake: tls,
                    requestSent: reqSent,
                    waitingForResponse: waiting,
                    responseReceived: respReceived,
                    total: duration
                )
            }()

            var entry = NetworkEntry(
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
                responseSize: body?.count,
                metrics: metrics,
                redirectCount: redirectCount
            )
            entry.redirects = redirects
            entry.isReplay = pending?.isReplay ?? false

            Task { @MainActor in
                self.store?.addNetworkEntry(entry)
            }
        }
    }

    // MARK: - Mock Response Logging

    func logMockResponse(
        requestID: UUID,
        statusCode: Int,
        headers: [String: String],
        body: String?,
        duration: TimeInterval
    ) {
        queue.async { [weak self] in
            guard let self else { return }

            let pending = self.pendingRequests.removeValue(forKey: requestID)

            var entry = NetworkEntry(
                id: pending?.id ?? UUID(),
                timestamp: pending?.timestamp ?? Date(),
                type: .network,
                requestURL: pending?.requestURL ?? "Unknown",
                requestMethod: pending?.requestMethod ?? "GET",
                requestHeaders: pending?.requestHeaders ?? [:],
                requestBody: pending?.requestBody,
                responseStatusCode: statusCode,
                responseHeaders: headers.isEmpty ? nil : headers,
                responseBody: body,
                responseError: nil,
                authToken: pending?.authToken,
                authTokenType: pending?.authTokenType,
                authTokenLength: pending?.authTokenLength,
                duration: duration,
                requestSize: pending?.requestSize,
                responseSize: body?.data(using: .utf8)?.count,
                metrics: nil
            )
            entry.isMocked = true

            Task { @MainActor in
                self.store?.addNetworkEntry(entry)
            }
        }
    }

    // MARK: - Helpers

    private func bodyToString(_ data: Data?) -> String? {
        guard let data else { return nil }

        // Check for image data (PNG, JPEG, GIF, WebP magic bytes)
        if data.count >= 4 {
            let bytes = [UInt8](data.prefix(4))
            let isImage = bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) || // PNG
                          bytes.starts(with: [0xFF, 0xD8, 0xFF]) ||        // JPEG
                          bytes.starts(with: [0x47, 0x49, 0x46]) ||        // GIF
                          bytes.starts(with: [0x52, 0x49, 0x46, 0x46])     // WebP (RIFF)
            if isImage {
                let base64 = data.prefix(500_000).base64EncodedString() // Max 500KB for images
                return "[IMAGE:\(data.count):\(base64)]"
            }
        }

        let maxSize = 1_000_000

        // Store raw UTF-8 string when possible — CodeBlockView handles pretty-printing for display.
        // This preserves the original bytes so Replay can reconstruct the exact request.
        if data.count <= maxSize, let rawString = String(data: data, encoding: .utf8) {
            return rawString
        }

        // For oversized text bodies, use placeholder so Replay knows to skip
        if let _ = String(data: data.prefix(maxSize), encoding: .utf8) {
            return "[Truncated: \(data.count) bytes]"
        }

        // Try the binary decoder hook installed by PryPro (e.g. raw protobuf).
        // Free builds without PryPro have no decoder, so unknown binary bodies
        // fall through to the placeholder.
        if let decoder = PryHooks.binaryBodyDecoder, let decoded = decoder(data) {
            return "[Binary: \(data.count) bytes]\n\(decoded)"
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
