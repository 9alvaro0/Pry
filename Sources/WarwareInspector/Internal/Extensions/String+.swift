import Foundation
import SwiftUI

extension String {

    // MARK: - URL parts

    private var parsedURL: URL? { URL(string: self) }

    func extractProtocol() -> String {
        components(separatedBy: "://").first ?? ""
    }

    func extractHost() -> String {
        guard let url = parsedURL else { return self }
        return url.host ?? self
    }

    func extractPath() -> String {
        guard let url = parsedURL else { return "/" }
        let path = url.path
        return path.isEmpty ? "/" : path
    }

    func extractQuery() -> String? {
        guard let query = parsedURL?.query,
              !query.isEmpty else { return nil }
        return query
    }

    // MARK: - HTTP

    func methodColor() -> Color {
        InspectorTheme.Colors.methodColor(self)
    }

    func sanitizedURL() -> String {
        guard let urlComponents = URLComponents(string: self) else { return self }

        var sanitized = urlComponents

        sanitized.queryItems = sanitized.queryItems?.compactMap { queryItem in
            let sensitiveParams = ["token", "auth", "password", "secret", "key", "session"]
            if sensitiveParams.contains(where: { queryItem.name.lowercased().contains($0) }) {
                return URLQueryItem(name: queryItem.name, value: "[REDACTED]")
            }
            return queryItem
        }

        return sanitized.url?.absoluteString ?? self
    }

    func sanitizedError() -> String {
        var sanitized = self

        sanitized = sanitized.replacingOccurrences(
            of: #"Bearer [A-Za-z0-9\-\._~\+\/]+=*"#,
            with: "Bearer [REDACTED]",
            options: .regularExpression
        )

        sanitized = sanitized.replacingOccurrences(
            of: #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#,
            with: "[EMAIL_REDACTED]",
            options: .regularExpression
        )

        return sanitized
    }
}
