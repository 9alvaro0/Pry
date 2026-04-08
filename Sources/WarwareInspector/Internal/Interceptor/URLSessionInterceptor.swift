import Foundation

/// URLProtocol subclass that transparently intercepts all URLSession traffic.
final class InspectorURLProtocol: URLProtocol, @unchecked Sendable {

    nonisolated(unsafe) static var logger: NetworkLogger?
    nonisolated(unsafe) static var blacklistedHosts: Set<String> = []
    nonisolated(unsafe) static var mockRules: [MockRule] = []
    nonisolated(unsafe) static var isMockingEnabled: Bool = false
    nonisolated(unsafe) static var throttle: NetworkThrottle = .none

    private static let handledKey = "WarwareInspector.handled"

    private var dataTask: URLSessionDataTask?
    private var receivedData = Data()
    private var response: URLResponse?
    private var startTime = Date()
    private var requestID: UUID?
    private var taskMetrics: URLSessionTaskMetrics?
    private var redirectCount = 0

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

        // Apply network throttle
        let throttle = Self.throttle
        if throttle == .offline || (throttle.failureRate > 0 && Double.random(in: 0...1) < throttle.failureRate) {
            // Simulate failure
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

        // Apply delay then proceed
        let proceed = { [self] in
            let session = Self.sharedSession(delegate: self)
            self.dataTask = session.dataTask(with: mutableRequest as URLRequest)
            self.dataTask?.resume()
        }

        if throttle.delay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + throttle.delay) {
                proceed()
            }
        } else {
            proceed()
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
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData.append(data)
        client?.urlProtocol(self, didLoad: data)
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

        if let requestID {
            let httpResponse = response as? HTTPURLResponse
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
