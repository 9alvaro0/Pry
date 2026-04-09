import Foundation
import SwiftUI

@_spi(PryPro) public extension String {

    // MARK: - URL parts

    private var parsedURL: URL? { URL(string: self) }

    @_spi(PryPro) public func extractProtocol() -> String {
        components(separatedBy: "://").first ?? ""
    }

    @_spi(PryPro) public func extractHost() -> String {
        guard let url = parsedURL else { return self }
        return url.host ?? self
    }

    @_spi(PryPro) public func extractPath() -> String {
        guard let url = parsedURL else { return "/" }
        let path = url.path
        return path.isEmpty ? "/" : path
    }

    @_spi(PryPro) public func extractQuery() -> String? {
        guard let query = parsedURL?.query,
              !query.isEmpty else { return nil }
        return query
    }

    // MARK: - HTTP

    @_spi(PryPro) public func methodColor() -> Color {
        PryTheme.Colors.methodColor(self)
    }

    @_spi(PryPro) public func sanitizedURL() -> String {
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

    @_spi(PryPro) public func sanitizedError() -> String {
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
