import Foundation

/// Generates cURL commands from network entries. Shared between detail view and swipe actions.
enum NetworkCurlGenerator {
    private static let internalHeaders: Set<String> = ["Content-Length", "Accept-Encoding", "X-Pry-Replay"]
    private static let skipHeaders: Set<String> = ["Host", "User-Agent"]

    static func generate(for entry: NetworkEntry) -> String {
        var components: [String] = ["curl", "--location", "--silent", "--show-error"]

        if entry.requestMethod != "GET" {
            components.append("--request \(entry.requestMethod)")
        }

        let headers = entry.requestHeaders.filter { key, _ in
            !key.hasPrefix("X-Debug-") && !internalHeaders.contains(key) && !skipHeaders.contains(key)
        }

        if let token = entry.authToken, !token.isEmpty {
            let authToken = token.hasPrefix("Bearer ") ? token : "Bearer \(token)"
            components.append("--header 'Authorization: \(escape(authToken))'")
        } else if let authHeader = headers["Authorization"] {
            components.append("--header 'Authorization: \(escape(authHeader))'")
        }

        for (key, value) in headers.sorted(by: { $0.key < $1.key }) where key != "Authorization" {
            components.append("--header '\(escape(key)): \(escape(value))'")
        }

        if entry.requestBody != nil && !headers.keys.contains("Content-Type") {
            components.append("--header 'Content-Type: application/json'")
        }

        if let body = entry.requestBody, !body.isEmpty {
            components.append("--data '\(escape(body))'")
        }

        components.append("'\(escape(entry.requestURL))'")

        return components.joined(separator: " \\\n  ")
    }

    private static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "'\"'\"'")
    }
}
