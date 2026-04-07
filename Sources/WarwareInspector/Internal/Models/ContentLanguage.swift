import Foundation

/// Content type detection for code block rendering.
enum ContentLanguage: String, CaseIterable {
    case json = "json"
    case text = "text"
    case http = "http"
    case html = "html"
    case xml = "xml"
    case javascript = "javascript"
    case plain = "plain"

    var displayName: String {
        switch self {
        case .json: return "JSON"
        case .text, .plain: return "Text"
        case .http: return "HTTP"
        case .html: return "HTML"
        case .xml: return "XML"
        case .javascript: return "JavaScript"
        }
    }

    var uppercased: String {
        return displayName.uppercased()
    }

    static func detect(from content: String) -> ContentLanguage {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.contains("HTTP/") || (trimmed.contains("GET ") || trimmed.contains("POST ") ||
                                        trimmed.contains("PUT ") || trimmed.contains("DELETE ") ||
                                        trimmed.contains("PATCH ") || trimmed.contains("HEAD ")) {
            return .http
        }

        if isValidJSON(trimmed) {
            return .json
        }

        if trimmed.lowercased().contains("<html") || trimmed.lowercased().contains("<!doctype html") {
            return .html
        }

        if trimmed.hasPrefix("<?xml") || (trimmed.hasPrefix("<") && trimmed.hasSuffix(">") && trimmed.contains("</")) {
            return .xml
        }

        return .text
    }

    private static func isValidJSON(_ string: String) -> Bool {
        guard !string.isEmpty else { return false }

        let startsWithBrace = string.hasPrefix("{") && string.hasSuffix("}")
        let startsWithBracket = string.hasPrefix("[") && string.hasSuffix("]")

        guard startsWithBrace || startsWithBracket else { return false }
        guard let data = string.data(using: .utf8) else { return false }

        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            return true
        } catch {
            return false
        }
    }

}
