import Foundation

/// URLProtocol subclass that transparently intercepts all URLSession traffic.
final class InspectorURLProtocol: URLProtocol, @unchecked Sendable {

    nonisolated(unsafe) static var logger: NetworkLogger?
    nonisolated(unsafe) static var blacklistedHosts: Set<String> = []

    private static let handledKey = "WarwareInspector.handled"

    private var dataTask: URLSessionDataTask?
    private var receivedData = Data()
    private var response: URLResponse?
    private var startTime = Date()
    private var requestID: UUID?
    private var taskMetrics: URLSessionTaskMetrics?
    private var redirectCount = 0

    // Shared session to preserve connection pooling
    nonisolated(unsafe) private static var forwardingSession: URLSession?

    private static func sharedSession(delegate: URLSessionDataDelegate) -> URLSession {
        // Each protocol instance needs its own session for delegate callbacks
        URLSession(
            configuration: {
                let config = URLSessionConfiguration.default
                // Don't register our protocol on the forwarding session (prevents recursion)
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

        // Log request start and get correlation ID
        if let url = request.url {
            requestID = Self.logger?.logRequest(
                url: url.absoluteString,
                method: request.httpMethod ?? "UNKNOWN",
                headers: request.allHTTPHeaderFields ?? [:],
                body: request.httpBody
            )
        }

        let session = Self.sharedSession(delegate: self)
        dataTask = session.dataTask(with: mutableRequest as URLRequest)
        dataTask?.resume()
    }

    override public func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
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
