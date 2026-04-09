import Foundation

/// URLProtocol subclass that transparently intercepts all URLSession traffic.
final class PryURLProtocol: URLProtocol, @unchecked Sendable {

    private static var config: PryConfig { PryConfig.shared }

    private static let handledKey = "Pry.handled"

    private var dataTask: URLSessionDataTask?
    private var receivedData = Data()
    private var response: URLResponse?
    private var startTime = Date()
    private var requestID: UUID?
    private var taskMetrics: URLSessionTaskMetrics?
    private var redirectCount = 0
    private var redirects: [RedirectHop] = []
    private var hasResponseBreakpoint = false
    private var matchedBreakpointRule: BreakpointRule?

    private static func sharedSession(delegate: URLSessionDataDelegate) -> URLSession {
        URLSession(
            configuration: {
                let config = URLSessionConfiguration.default
                config.protocolClasses = config.protocolClasses?.filter { $0 != PryURLProtocol.self }
                return config
            }(),
            delegate: delegate,
            delegateQueue: nil
        )
    }

    // MARK: - URLProtocol

    override public class func canInit(with request: URLRequest) -> Bool {
        if let host = request.url?.host, config.blacklistedHosts.contains(host) {
            return false
        }
        guard config.logger != nil else { return false }
        return URLProtocol.property(forKey: handledKey, in: request) == nil
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override public func startLoading() {
        startTime = Date()

        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)

        // Strip internal replay header before forwarding to real server
        mutableRequest.setValue(nil, forHTTPHeaderField: "X-Pry-Replay")

        // Recover the request body from the body stream if needed, then reinject it
        // as httpBody so every downstream consumer (logger, URLSession, breakpoint
        // editor, replay) sees the same bytes. URLSession strips httpBody → httpBodyStream
        // before handing the request to URLProtocol, so reading the stream is the only
        // way to recover the payload — and we read from the mutable copy to make sure
        // the stream we consume is the same one that would otherwise be sent.
        let bodyData = Self.extractBody(from: mutableRequest as URLRequest)
        if let bodyData {
            mutableRequest.httpBody = bodyData
        }

        // Log request start
        if let url = request.url {
            requestID = Self.config.logger?.logRequest(
                url: url.absoluteString,
                method: request.httpMethod ?? "UNKNOWN",
                headers: request.allHTTPHeaderFields ?? [:],
                body: bodyData
            )
        }

        // Check for mock response BEFORE making real request
        if Self.config.isMockingEnabled, let rule = Self.config.findMatchingMock(for: request) {
            respondWithMock(rule)
            return
        }

        // Check for request breakpoint BEFORE sending
        if Self.config.isBreakpointEnabled,
           let rule = Self.config.findMatchingBreakpoint(for: request),
           rule.pauseOn == .request || rule.pauseOn == .both {
            let capturedRequest = mutableRequest as URLRequest
            handleBreakpoint(request: capturedRequest, rule: rule)
            return
        }

        // Check if we need to intercept the response
        if Self.config.isBreakpointEnabled,
           let rule = Self.config.findMatchingBreakpoint(for: request),
           rule.pauseOn == .response || rule.pauseOn == .both {
            hasResponseBreakpoint = true
            matchedBreakpointRule = rule
        }

        // Send the request (applies throttle internally)
        proceedWithRequest(mutableRequest as URLRequest)
    }

    /// Sends the request to the real server, applying throttle if needed.
    private func proceedWithRequest(_ request: URLRequest) {
        let throttle = Self.config.throttle

        // Apply throttle
        if throttle == .offline || (throttle.failureRate > 0 && Double.random(in: 0...1) < throttle.failureRate) {
            let delay = throttle.delay
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                let error = URLError(.notConnectedToInternet)
                if let requestID = self.requestID {
                    Self.config.logger?.logResponse(
                        requestID: requestID,
                        statusCode: 0,
                        headers: [:],
                        body: nil,
                        error: error,
                        duration: delay,
                        taskMetrics: nil,
                        redirectCount: 0
                    )
                }
                self.client?.urlProtocol(self, didFailWithError: error)
            }
            return
        }

        let send = { [weak self] in
            guard let self else { return }
            let session = Self.sharedSession(delegate: self)
            self.dataTask = session.dataTask(with: request)
            self.dataTask?.resume()
        }

        if throttle.delay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + throttle.delay) {
                send()
            }
        } else {
            send()
        }
    }

    override public func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
    }

    // MARK: - Body Extraction

    /// Extracts the request body, reading from `httpBodyStream` when `httpBody` is nil.
    ///
    /// URLSession converts `httpBody` to `httpBodyStream` before passing the request
    /// to URLProtocol, so `request.httpBody` is always nil in `startLoading()` for
    /// requests created with `httpBody`. Reading the stream recovers the bytes.
    private static func extractBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else { return nil }

        stream.open()
        defer { stream.close() }

        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        var data = Data()
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 {
                data.append(buffer, count: read)
            } else {
                break
            }
        }
        return data.isEmpty ? nil : data
    }

    // MARK: - Mock Response

    /// Timeout for breakpoint user interaction (seconds).
    private static let breakpointTimeout: TimeInterval = 120

    /// Bridges async BreakpointManager call to sync URLProtocol thread via semaphore.
    /// Handles timeout and cancellation. Calls `onResult` on a background queue.
    private func awaitBreakpointAction(
        pause: @escaping () async -> BreakpointManager.BreakpointAction,
        onResult: @escaping (BreakpointManager.BreakpointAction) -> Void
    ) {
        nonisolated(unsafe) let protocolSelf = self
        DispatchQueue.global(qos: .userInitiated).async {
            let semaphore = DispatchSemaphore(value: 0)
            nonisolated(unsafe) var result: BreakpointManager.BreakpointAction = .cancel

            Task {
                result = await pause()
                semaphore.signal()
            }

            let waitResult = semaphore.wait(timeout: .now() + Self.breakpointTimeout)
            if waitResult == .timedOut {
                Task { @MainActor in BreakpointManager.shared.cancelRequest() }
                protocolSelf.client?.urlProtocol(protocolSelf, didFailWithError: URLError(.timedOut))
                return
            }

            onResult(result)
        }
    }

    private func handleResponseBreakpoint(
        rule: BreakpointRule,
        statusCode: Int,
        headers: [String: String],
        body: String?,
        duration: TimeInterval
    ) {
        nonisolated(unsafe) let protocolSelf = self
        let originalRequest = self.request
        let requestID = self.requestID

        awaitBreakpointAction(
            pause: {
                await BreakpointManager.shared.pauseResponse(
                    request: originalRequest, rule: rule,
                    statusCode: statusCode, headers: headers, body: body
                )
            },
            onResult: { result in
                switch result {
                case .sendResponse(let modifiedStatus, let modifiedHeaders, let modifiedBody):
                    let url = originalRequest.url ?? URL(string: "about:blank")!
                    if let httpResponse = HTTPURLResponse(url: url, statusCode: modifiedStatus, httpVersion: "HTTP/1.1", headerFields: modifiedHeaders) {
                        protocolSelf.client?.urlProtocol(protocolSelf, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
                    }
                    if let modifiedBody, let data = modifiedBody.data(using: .utf8) {
                        protocolSelf.client?.urlProtocol(protocolSelf, didLoad: data)
                    }
                    protocolSelf.client?.urlProtocolDidFinishLoading(protocolSelf)

                    if let requestID {
                        Self.config.logger?.logResponse(
                            requestID: requestID, statusCode: modifiedStatus, headers: modifiedHeaders,
                            body: modifiedBody?.data(using: .utf8), error: nil,
                            duration: duration, taskMetrics: nil, redirectCount: 0
                        )
                    }
                case .send, .cancel:
                    protocolSelf.client?.urlProtocol(protocolSelf, didFailWithError: URLError(.cancelled))
                }
            }
        )
    }

    private func handleBreakpoint(request: URLRequest, rule: BreakpointRule) {
        nonisolated(unsafe) let protocolSelf = self

        awaitBreakpointAction(
            pause: { await BreakpointManager.shared.pauseRequest(request, rule: rule) },
            onResult: { result in
                switch result {
                case .send(let modified):
                    guard let modifiedMutable = (modified as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
                        protocolSelf.client?.urlProtocol(protocolSelf, didFailWithError: URLError(.badURL))
                        return
                    }
                    URLProtocol.setProperty(true, forKey: Self.handledKey, in: modifiedMutable)
                    if rule.pauseOn == .both {
                        protocolSelf.hasResponseBreakpoint = true
                        protocolSelf.matchedBreakpointRule = rule
                    }
                    protocolSelf.proceedWithRequest(modifiedMutable as URLRequest)
                case .sendResponse:
                    break
                case .cancel:
                    protocolSelf.client?.urlProtocol(protocolSelf, didFailWithError: URLError(.cancelled))
                }
            }
        )
    }

    private func respondWithMock(_ rule: MockRule) {
        let url = request.url ?? URL(string: "about:blank")!

        // Simulate delay if configured
        let deliver = { [weak self] in
            guard let self else { return }

            // Build HTTP response
            let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: rule.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: rule.responseHeaders
            )

            if let httpResponse {
                self.client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            }

            // Send body data
            if let body = rule.responseBody, let data = body.data(using: .utf8) {
                self.client?.urlProtocol(self, didLoad: data)
            }

            // Finish
            self.client?.urlProtocolDidFinishLoading(self)

            // Log mock response
            let duration = Date().timeIntervalSince(self.startTime)
            if let requestID = self.requestID {
                Self.config.logger?.logMockResponse(
                    requestID: requestID,
                    statusCode: rule.statusCode,
                    headers: rule.responseHeaders,
                    body: rule.responseBody,
                    duration: duration
                )
            }
        }

        if rule.delay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + rule.delay) {
                deliver()
            }
        } else {
            deliver()
        }
    }
}

// MARK: - URLSessionDataDelegate

extension PryURLProtocol: URLSessionDataDelegate {

    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        self.response = response
        // If response breakpoint is active, don't forward yet — we'll deliver after editing
        if !hasResponseBreakpoint {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
        }
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData.append(data)
        // If response breakpoint is active, buffer data instead of forwarding
        if !hasResponseBreakpoint {
            client?.urlProtocol(self, didLoad: data)
        }
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        redirectCount += 1
        if let from = response.url?.absoluteString, let to = request.url?.absoluteString {
            redirects.append(RedirectHop(
                fromURL: from,
                statusCode: response.statusCode,
                toURL: to
            ))
        }
        completionHandler(request)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        self.taskMetrics = metrics
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let duration = Date().timeIntervalSince(startTime)
        let httpResponse = response as? HTTPURLResponse

        // Response breakpoint: pause before delivering to the app
        if hasResponseBreakpoint, error == nil, let rule = matchedBreakpointRule {
            let statusCode = httpResponse?.statusCode ?? 200
            let headers = (httpResponse?.allHeaderFields as? [String: String]) ?? [:]
            let bodyString = receivedData.isEmpty ? nil : String(data: receivedData, encoding: .utf8)

            handleResponseBreakpoint(
                rule: rule,
                statusCode: statusCode,
                headers: headers,
                body: bodyString,
                duration: duration
            )
            return
        }

        if let requestID {
            Self.config.logger?.logResponse(
                requestID: requestID,
                statusCode: httpResponse?.statusCode ?? 0,
                headers: (httpResponse?.allHeaderFields as? [String: String]) ?? [:],
                body: receivedData,
                error: error,
                duration: duration,
                taskMetrics: taskMetrics,
                redirectCount: redirectCount,
                redirects: redirects
            )
        }

        if let error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
}
