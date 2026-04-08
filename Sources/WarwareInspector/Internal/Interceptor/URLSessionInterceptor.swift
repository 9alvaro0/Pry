import Foundation

/// URLProtocol subclass that transparently intercepts all URLSession traffic.
final class InspectorURLProtocol: URLProtocol, @unchecked Sendable {

    nonisolated(unsafe) static var logger: NetworkLogger?
    nonisolated(unsafe) static var blacklistedHosts: Set<String> = []
    nonisolated(unsafe) static var mockRules: [MockRule] = []
    nonisolated(unsafe) static var isMockingEnabled: Bool = false
    nonisolated(unsafe) static var throttle: NetworkThrottle = .none
    nonisolated(unsafe) static var breakpointRules: [BreakpointRule] = []
    nonisolated(unsafe) static var isBreakpointEnabled: Bool = false

    private static let handledKey = "WarwareInspector.handled"

    private var dataTask: URLSessionDataTask?
    private var receivedData = Data()
    private var response: URLResponse?
    private var startTime = Date()
    private var requestID: UUID?
    private var taskMetrics: URLSessionTaskMetrics?
    private var redirectCount = 0
    private var hasResponseBreakpoint = false
    private var matchedBreakpointRule: BreakpointRule?

    private static func sharedSession(delegate: URLSessionDataDelegate) -> URLSession {
        URLSession(
            configuration: {
                let config = URLSessionConfiguration.default
                config.protocolClasses = config.protocolClasses?.filter { $0 != InspectorURLProtocol.self }
                return config
            }(),
            delegate: delegate,
            delegateQueue: nil
        )
    }

    // MARK: - URLProtocol

    override public class func canInit(with request: URLRequest) -> Bool {
        if let host = request.url?.host, blacklistedHosts.contains(host) {
            return false
        }
        guard logger != nil else { return false }
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
        mutableRequest.setValue(nil, forHTTPHeaderField: "X-WarwareInspector-Replay")

        // Log request start
        if let url = request.url {
            requestID = Self.logger?.logRequest(
                url: url.absoluteString,
                method: request.httpMethod ?? "UNKNOWN",
                headers: request.allHTTPHeaderFields ?? [:],
                body: request.httpBody
            )
        }

        // Check for mock response BEFORE making real request
        if Self.isMockingEnabled, let rule = Self.findMatchingMock(for: request) {
            respondWithMock(rule)
            return
        }

        // Check for request breakpoint BEFORE sending
        if Self.isBreakpointEnabled,
           let rule = Self.findMatchingBreakpoint(for: request),
           rule.pauseOn == .request || rule.pauseOn == .both {
            let capturedRequest = mutableRequest as URLRequest
            handleBreakpoint(request: capturedRequest, rule: rule)
            return
        }

        // Check if we need to intercept the response
        if Self.isBreakpointEnabled,
           let rule = Self.findMatchingBreakpoint(for: request),
           rule.pauseOn == .response || rule.pauseOn == .both {
            hasResponseBreakpoint = true
            matchedBreakpointRule = rule
        }

        // Send the request (applies throttle internally)
        proceedWithRequest(mutableRequest as URLRequest)
    }

    /// Sends the request to the real server, applying throttle if needed.
    private func proceedWithRequest(_ request: URLRequest) {
        let throttle = Self.throttle

        // Apply throttle
        if throttle == .offline || (throttle.failureRate > 0 && Double.random(in: 0...1) < throttle.failureRate) {
            let delay = throttle.delay
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                let error = URLError(.notConnectedToInternet)
                if let requestID = self.requestID {
                    Self.logger?.logResponse(
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

    // MARK: - Mock Response

    private static func findMatchingMock(for request: URLRequest) -> MockRule? {
        mockRules.first { $0.matches(request) }
    }

    private static func findMatchingBreakpoint(for request: URLRequest) -> BreakpointRule? {
        breakpointRules.first { $0.matches(request) }
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

        DispatchQueue.global(qos: .userInitiated).async {
            let semaphore = DispatchSemaphore(value: 0)
            nonisolated(unsafe) var result: BreakpointManager.BreakpointAction = .cancel

            Task {
                result = await BreakpointManager.shared.pauseResponse(
                    request: originalRequest,
                    rule: rule,
                    statusCode: statusCode,
                    headers: headers,
                    body: body
                )
                semaphore.signal()
            }

            let waitResult = semaphore.wait(timeout: .now() + Self.breakpointTimeout)
            if waitResult == .timedOut {
                Task { @MainActor in BreakpointManager.shared.cancelRequest() }
                protocolSelf.client?.urlProtocol(protocolSelf, didFailWithError: URLError(.timedOut))
                return
            }

            switch result {
            case .sendResponse(let modifiedStatus, let modifiedHeaders, let modifiedBody):
                let url = originalRequest.url ?? URL(string: "about:blank")!
                let httpResponse = HTTPURLResponse(
                    url: url,
                    statusCode: modifiedStatus,
                    httpVersion: "HTTP/1.1",
                    headerFields: modifiedHeaders
                )

                if let httpResponse {
                    protocolSelf.client?.urlProtocol(protocolSelf, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
                }

                if let modifiedBody, let data = modifiedBody.data(using: .utf8) {
                    protocolSelf.client?.urlProtocol(protocolSelf, didLoad: data)
                }

                protocolSelf.client?.urlProtocolDidFinishLoading(protocolSelf)

                if let requestID {
                    Self.logger?.logResponse(
                        requestID: requestID,
                        statusCode: modifiedStatus,
                        headers: modifiedHeaders,
                        body: modifiedBody?.data(using: .utf8),
                        error: nil,
                        duration: duration,
                        taskMetrics: nil,
                        redirectCount: 0
                    )
                }

            case .send:
                // Shouldn't happen for response breakpoints, but handle gracefully
                protocolSelf.client?.urlProtocolDidFinishLoading(protocolSelf)

            case .cancel:
                protocolSelf.client?.urlProtocol(protocolSelf, didFailWithError: URLError(.cancelled))
            }
        }
    }

    /// Timeout for breakpoint user interaction (seconds).
    private static let breakpointTimeout: TimeInterval = 120

    private func handleBreakpoint(request: URLRequest, rule: BreakpointRule) {
        nonisolated(unsafe) let protocolSelf = self
        DispatchQueue.global(qos: .userInitiated).async {
            let semaphore = DispatchSemaphore(value: 0)
            nonisolated(unsafe) var result: BreakpointManager.BreakpointAction = .cancel

            Task {
                result = await BreakpointManager.shared.pauseRequest(request, rule: rule)
                semaphore.signal()
            }

            let waitResult = semaphore.wait(timeout: .now() + Self.breakpointTimeout)
            if waitResult == .timedOut {
                Task { @MainActor in BreakpointManager.shared.cancelRequest() }
                protocolSelf.client?.urlProtocol(protocolSelf, didFailWithError: URLError(.timedOut))
                return
            }

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
                Self.logger?.logMockResponse(
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

extension InspectorURLProtocol: URLSessionDataDelegate {

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
            Self.logger?.logResponse(
                requestID: requestID,
                statusCode: httpResponse?.statusCode ?? 0,
                headers: (httpResponse?.allHeaderFields as? [String: String]) ?? [:],
                body: receivedData,
                error: error,
                duration: duration,
                taskMetrics: taskMetrics,
                redirectCount: redirectCount
            )
        }

        if let error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
}
