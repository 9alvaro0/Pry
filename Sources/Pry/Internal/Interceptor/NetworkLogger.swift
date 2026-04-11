import Foundation

/// Captures and logs network requests/responses into the PryStore.
final class NetworkLogger: @unchecked Sendable {

    private weak var store: PryStore?
    private var pendingRequests: [UUID: NetworkEntry] = [:]
    private let queue = DispatchQueue(label: "Pry.NetworkLogger", qos: .utility)
    private var lastCleanup = Date()

    init(store: PryStore) {
        self.store = store
        startCleanupTimer()
    }

    private func startCleanupTimer() {
        queue.asyncAfter(deadline: .now() + 60) { [weak self] in
            self?.cleanupOrphaned()
            self?.startCleanupTimer()
        }
    }

    private func cleanupOrphaned() {
        let cutoff = Date().addingTimeInterval(-300)
        for (id, entry) in pendingRequests where entry.timestamp <= cutoff {
            pendingRequests.removeValue(forKey: id)
        }
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

            // Evict orphaned requests older than 5 minutes (checked every 60s)
            let now = Date()
            if now.timeIntervalSince(self.lastCleanup) > 60 {
                self.lastCleanup = now
                let cutoff = now.addingTimeInterval(-300)
                self.pendingRequests = self.pendingRequests.filter { $0.value.timestamp > cutoff }
            }

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
            let isImage = data.withUnsafeBytes { ptr -> Bool in
                guard let base = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return false }
                let b0 = base[0], b1 = base[1], b2 = base[2], b3 = base[3]
                return (b0 == 0x89 && b1 == 0x50 && b2 == 0x4E && b3 == 0x47) || // PNG
                       (b0 == 0xFF && b1 == 0xD8 && b2 == 0xFF) ||               // JPEG
                       (b0 == 0x47 && b1 == 0x49 && b2 == 0x46) ||               // GIF
                       (b0 == 0x52 && b1 == 0x49 && b2 == 0x46 && b3 == 0x46)    // WebP (RIFF)
            }
            if isImage {
                // Cap at 512KB for preview — larger images store metadata only
                if data.count <= 512_000 {
                    let base64 = data.base64EncodedString()
                    return "[IMAGE:\(data.count):\(base64)]"
                } else {
                    return "[IMAGE:\(data.count):]"
                }
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
