import Foundation

/// Exports captured network entries as Postman Collection or cURL commands.
enum SessionExporter {

    // MARK: - Postman Collection v2.1

    /// Generates a Postman Collection v2.1 JSON from the given entries.
    static func postmanCollection(entries: [NetworkEntry], name: String = "WarwareInspector Export") -> String {
        let items: [[String: Any]] = entries.map { entry in
            var item: [String: Any] = [:]
            item["name"] = "\(entry.requestMethod) \(entry.displayPath)"

            // Request
            var request: [String: Any] = [:]
            request["method"] = entry.requestMethod
            request["url"] = buildPostmanURL(entry.requestURL)

            // Headers
            let headers: [[String: Any]] = exportHeaders(entry.requestHeaders)
                .sorted { $0.key < $1.key }
                .map { ["key": $0.key, "value": $0.value, "type": "text"] }
            request["header"] = headers

            // Body
            if let body = entry.requestBody, !body.isEmpty,
               !body.hasPrefix("[IMAGE:"), !body.hasPrefix("[Binary data:") {
                let contentType = entry.requestHeaders["Content-Type"] ?? ""
                if contentType.contains("x-www-form-urlencoded") {
                    request["body"] = [
                        "mode": "urlencoded",
                        "urlencoded": parseFormData(body)
                    ] as [String: Any]
                } else {
                    request["body"] = [
                        "mode": "raw",
                        "raw": body,
                        "options": ["raw": ["language": "json"]]
                    ] as [String: Any]
                }
            }

            item["request"] = request

            // Response (include as example)
            if let statusCode = entry.responseStatusCode {
                var response: [String: Any] = [:]
                response["name"] = "\(statusCode) Response"
                response["status"] = HTTPStatus.description(for: statusCode)
                response["code"] = statusCode

                if let resHeaders = entry.responseHeaders {
                    response["header"] = resHeaders.map { ["key": $0.key, "value": $0.value, "type": "text"] }
                }
                if let body = entry.responseBody {
                    response["body"] = body
                }

                item["response"] = [response]
            }

            return item
        }

        let collection: [String: Any] = [
            "info": [
                "name": name,
                "description": "Exported from WarwareInspector on \(Date().formatted())",
                "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
            ],
            "item": items
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: collection, options: [.prettyPrinted, .sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return json
    }

    // MARK: - cURL Collection

    /// Generates a file with all entries as cURL commands separated by blank lines.
    static func curlCollection(entries: [NetworkEntry]) -> String {
        entries.map { curlCommand(for: $0) }.joined(separator: "\n\n")
    }

    /// Generates a single cURL command for an entry.
    static func curlCommand(for entry: NetworkEntry) -> String {
        var components: [String] = ["curl", "--location", "--silent", "--show-error"]

        if entry.requestMethod != "GET" {
            components.append("--request \(entry.requestMethod)")
        }

        for (key, value) in exportHeaders(entry.requestHeaders, skipExtra: curlExtraSkip).sorted(by: { $0.key < $1.key }) {
            components.append("--header '\(escapeCurl(key)): \(escapeCurl(value))'")
        }

        if let body = entry.requestBody, !body.isEmpty,
           !body.hasPrefix("[IMAGE:"), !body.hasPrefix("[Binary data:") {
            components.append("--data '\(escapeCurl(body))'")
        }

        components.append("'\(escapeCurl(entry.requestURL))'")

        return components.joined(separator: " \\\n  ")
    }

    // MARK: - HAR (HTTP Archive)

    /// Generates a HAR 1.2 JSON from the given entries.
    static func harArchive(entries: [NetworkEntry]) -> String {
        let harEntries: [[String: Any]] = entries.compactMap { entry in
            var harEntry: [String: Any] = [:]
            harEntry["startedDateTime"] = entry.timestamp.formatted(.iso8601)
            harEntry["time"] = (entry.duration ?? 0) * 1000 // ms

            // Request
            var request: [String: Any] = [:]
            request["method"] = entry.requestMethod
            request["url"] = entry.requestURL
            request["httpVersion"] = "HTTP/1.1"
            request["headers"] = entry.requestHeaders.map { ["name": $0.key, "value": $0.value] }
            request["queryString"] = URLComponents(string: entry.requestURL)?.queryItems?.map {
                ["name": $0.name, "value": $0.value ?? ""]
            } ?? []
            request["cookies"] = [] as [Any]
            request["headersSize"] = -1
            request["bodySize"] = entry.requestSize ?? -1

            if let body = entry.requestBody, !body.hasPrefix("[IMAGE:"), !body.hasPrefix("[Binary data:") {
                request["postData"] = [
                    "mimeType": entry.requestHeaders["Content-Type"] ?? "application/json",
                    "text": body
                ]
            }

            harEntry["request"] = request

            // Response
            var response: [String: Any] = [:]
            response["status"] = entry.responseStatusCode ?? 0
            response["statusText"] = entry.responseStatusCode.map { HTTPStatus.description(for: $0) } ?? ""
            response["httpVersion"] = "HTTP/1.1"
            response["headers"] = (entry.responseHeaders ?? [:]).map { ["name": $0.key, "value": $0.value] }
            response["cookies"] = [] as [Any]
            response["redirectURL"] = ""
            response["headersSize"] = -1
            response["bodySize"] = entry.responseSize ?? -1

            var content: [String: Any] = [:]
            content["size"] = entry.responseSize ?? 0
            content["mimeType"] = entry.responseHeaders?["Content-Type"] ?? "application/json"
            if let body = entry.responseBody {
                content["text"] = body
            }
            response["content"] = content

            harEntry["response"] = response

            // Timings
            var timings: [String: Any] = [:]
            timings["dns"] = (entry.metrics?.dnsLookup ?? 0) * 1000
            timings["connect"] = (entry.metrics?.tcpConnect ?? 0) * 1000
            timings["ssl"] = (entry.metrics?.tlsHandshake ?? 0) * 1000
            timings["send"] = (entry.metrics?.requestSent ?? 0) * 1000
            timings["wait"] = (entry.metrics?.waitingForResponse ?? 0) * 1000
            timings["receive"] = (entry.metrics?.responseReceived ?? 0) * 1000
            harEntry["timings"] = timings
            harEntry["cache"] = [String: Any]()

            return harEntry
        }

        let har: [String: Any] = [
            "log": [
                "version": "1.2",
                "creator": ["name": "WarwareInspector", "version": "1.0"],
                "entries": harEntries
            ]
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: har, options: [.prettyPrinted, .sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return json
    }

    // MARK: - Helpers

    private static let skipHeaders: Set<String> = ["Content-Length", "Accept-Encoding", "Host", "X-WarwareInspector-Replay"]
    private static let curlExtraSkip: Set<String> = ["User-Agent"]

    private static func exportHeaders(_ headers: [String: String], skipExtra: Set<String> = []) -> [String: String] {
        headers.filter { key, _ in
            !key.hasPrefix("X-Debug-") && !skipHeaders.contains(key) && !skipExtra.contains(key)
        }
    }

    private static func escapeCurl(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "'\"'\"'")
    }

    private static func buildPostmanURL(_ urlString: String) -> [String: Any] {
        guard let components = URLComponents(string: urlString) else {
            return ["raw": urlString]
        }

        var url: [String: Any] = ["raw": urlString]
        url["protocol"] = components.scheme
        url["host"] = components.host?.components(separatedBy: ".") ?? []
        if let port = components.port {
            url["port"] = String(port)
        }
        url["path"] = components.path.split(separator: "/").map(String.init)

        if let queryItems = components.queryItems, !queryItems.isEmpty {
            url["query"] = queryItems.map { ["key": $0.name, "value": $0.value ?? ""] }
        }

        return url
    }

    private static func parseFormData(_ body: String) -> [[String: String]] {
        body.components(separatedBy: "&").compactMap { pair in
            let parts = pair.components(separatedBy: "=")
            guard let key = parts.first?.removingPercentEncoding else { return nil }
            let value = parts.count > 1 ? (parts[1].removingPercentEncoding ?? parts[1]) : ""
            return ["key": key, "value": value, "type": "text"]
        }
    }
}
