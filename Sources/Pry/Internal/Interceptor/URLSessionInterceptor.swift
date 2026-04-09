import Foundation

/// URLProtocol subclass that transparently intercepts all URLSession traffic.
///
/// The interceptor only knows about Free responsibilities: observing
/// requests, recovering their body, streaming responses back to the caller
/// and capturing redirect chains. Every Pro behavior — mocks, breakpoints,
/// throttle — is delegated to closures registered on ``PryInterceptorHooks``
/// by the PryPro module during `PryPro.install()`. When PryPro is not
/// linked, the hooks are `nil` and the interceptor behaves as a pure
/// passthrough logger.
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

        // Recover the request body from the body stream if needed, then reinject
        // it as httpBody so every downstream consumer (logger, URLSession,
        // breakpoint editor, replay) sees the same bytes. URLSession strips
        // httpBody → httpBodyStream before passing the request to URLProtocol,
        // so reading the stream is the only way to recover the payload.
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

        // Check for mock response BEFORE making a real request
        if let mockResponseFor = PryInterceptorHooks.mockResponseFor,
           let mock = mockResponseFor(request) {
            respondWithMock(mock)
            return
        }

        // Check for request breakpoint BEFORE sending
        if let pauseRequestIfNeeded = PryInterceptorHooks.pauseRequestIfNeeded,
           let waiter = pauseRequestIfNeeded(mutableRequest as URLRequest) {
            let capturedRequest = mutableRequest as URLRequest
            handleRequestBreakpoint(request: capturedRequest, waiter: waiter)
            return
        }

        // Check if we need to intercept the response
        if PryInterceptorHooks.shouldPauseResponse?(request) == true {
            hasResponseBreakpoint = true
        }

        // Send the request (applies throttle internally)
        proceedWithRequest(mutableRequest as URLRequest)
    }

    /// Sends the request to the real server, applying throttle if needed.
    private func proceedWithRequest(_ request: URLRequest) {
        let throttle = PryInterceptorHooks.throttle?() ?? .none

        // Apply throttle
        if throttle.isOffline || (throttle.failureRate > 0 && Double.random(in: 0...1) < throttle.failureRate) {
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

    // MARK: - Breakpoint Bridge

    /// Bridges the async breakpoint waiter to URLProtocol's synchronous thread
    /// via DispatchSemaphore, so the real send is suspended until the user acts.
    /// Honors the timeout configured in ``PryInterceptorHooks/breakpointTimeout``.
    private func awaitBreakpoint<Result: Sendable>(
        waiter: @escaping @Sendable () async -> Result,
        timeoutResult: Result,
        onResult: @escaping @Sendable (Result) -> Void
    ) {
        nonisolated(unsafe) let protocolSelf = self
        let timeout = PryInterceptorHooks.breakpointTimeout
        DispatchQueue.global(qos: .userInitiated).async {
            let semaphore = DispatchSemaphore(value: 0)
            nonisolated(unsafe) var result: Result = timeoutResult

            Task {
                result = await waiter()
                semaphore.signal()
            }

            let waitResult = semaphore.wait(timeout: .now() + timeout)
            if waitResult == .timedOut {
                protocolSelf.client?.urlProtocol(protocolSelf, didFailWithError: URLError(.timedOut))
                return
            }

            onResult(result)
        }
    }

    private func handleRequestBreakpoint(
        request: URLRequest,
        waiter: @escaping @Sendable () async -> ProRequestBreakpointResult
    ) {
        nonisolated(unsafe) let protocolSelf = self

        awaitBreakpoint(
            waiter: waiter,
            timeoutResult: .cancel,
            onResult: { result in
                switch result {
                case .send(let modified):
                    guard let modifiedMutable = (modified as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
                        protocolSelf.client?.urlProtocol(protocolSelf, didFailWithError: URLError(.badURL))
                        return
                    }
                    URLProtocol.setProperty(true, forKey: Self.handledKey, in: modifiedMutable)
                    // Response breakpoint flag is set below if needed
                    if PryInterceptorHooks.shouldPauseResponse?(modified) == true {
                        protocolSelf.hasResponseBreakpoint = true
                    }
                    protocolSelf.proceedWithRequest(modifiedMutable as URLRequest)
                case .cancel:
                    protocolSelf.client?.urlProtocol(protocolSelf, didFailWithError: URLError(.cancelled))
                }
            }
        )
    }

    private func handleResponseBreakpoint(
        statusCode: Int,
        headers: [String: String],
        body: String?,
        duration: TimeInterval
    ) {
        guard let pauseResponse = PryInterceptorHooks.pauseResponse else {
            // Hook is gone — just deliver as-is
            deliverBufferedResponse(duration: duration)
            return
        }

        nonisolated(unsafe) let protocolSelf = self
        let originalRequest = self.request
        let requestID = self.requestID

        awaitBreakpoint(
            waiter: {
                await pauseResponse(originalRequest, statusCode, headers, body)
            },
            timeoutResult: .cancel,
            onResult: { result in
                switch result {
                case .sendAsIs:
                    protocolSelf.deliverBufferedResponse(duration: duration)
                case .sendModified(let modifiedStatus, let modifiedHeaders, let modifiedBody):
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
                case .cancel:
                    protocolSelf.client?.urlProtocol(protocolSelf, didFailWithError: URLError(.cancelled))
                }
            }
        )
    }

    /// Flushes the buffered response to the client, used when a response
    /// breakpoint decides to let the original bytes through unchanged.
    private func deliverBufferedResponse(duration: TimeInterval) {
        if let httpResponse = response as? HTTPURLResponse {
            client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .allowed)
        }
        if !receivedData.isEmpty {
            client?.urlProtocol(self, didLoad: receivedData)
        }
        client?.urlProtocolDidFinishLoading(self)

        if let requestID {
            Self.config.logger?.logResponse(
                requestID: requestID,
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                headers: ((response as? HTTPURLResponse)?.allHeaderFields as? [String: String]) ?? [:],
                body: receivedData,
                error: nil,
                duration: duration,
                taskMetrics: taskMetrics,
                redirectCount: redirectCount,
                redirects: redirects
            )
        }
    }

    // MARK: - Mock Response

    private func respondWithMock(_ mock: ProMockResponse) {
        let url = request.url ?? URL(string: "about:blank")!

        let deliver = { [weak self] in
            guard let self else { return }

            let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: mock.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: mock.headers
            )

            if let httpResponse {
                self.client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            }

            if let body = mock.body, let data = body.data(using: .utf8) {
                self.client?.urlProtocol(self, didLoad: data)
            }

            self.client?.urlProtocolDidFinishLoading(self)

            let duration = Date().timeIntervalSince(self.startTime)

            if let requestID = self.requestID {
                Self.config.logger?.logMockResponse(
                    requestID: requestID,
                    statusCode: mock.statusCode,
                    headers: mock.headers,
                    body: mock.body,
                    duration: duration
                )
            }
        }

        if mock.delay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + mock.delay) {
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
        if hasResponseBreakpoint, error == nil {
            let statusCode = httpResponse?.statusCode ?? 200
            let headers = (httpResponse?.allHeaderFields as? [String: String]) ?? [:]
            let bodyString = receivedData.isEmpty ? nil : String(data: receivedData, encoding: .utf8)

            handleResponseBreakpoint(
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
