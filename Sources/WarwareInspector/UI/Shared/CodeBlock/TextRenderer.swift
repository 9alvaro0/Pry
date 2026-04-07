import SwiftUI

/// Renders plain text and HTTP content with expand/collapse and search highlight support.
struct TextRenderer: View {
    let text: String
    var language: ContentLanguage = .text
    var searchQuery: String = ""

    @State private var isExpanded = false

    private let collapsedLineLimit = 12

    private var lineCount: Int {
        text.components(separatedBy: .newlines).count
    }

    private var isLong: Bool {
        lineCount > collapsedLineLimit
    }

    private var isSearching: Bool { !searchQuery.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
            if language == .http {
                httpContent
            } else {
                plainTextContent
            }

            if isLong {
                expandButton
            }
        }
    }

    // MARK: - Plain Text

    @ViewBuilder
    private var plainTextContent: some View {
        let displayText = isExpanded ? text : truncatedText

        if isSearching {
            HighlightedText(
                text: displayText,
                query: searchQuery,
                baseColor: InspectorTheme.Colors.textPrimary
            )
            .font(InspectorTheme.Typography.code)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        } else {
            Text(displayText)
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                .textSelection(.enabled)
                .lineLimit(isExpanded ? nil : collapsedLineLimit)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var truncatedText: String {
        let lines = text.components(separatedBy: .newlines)
        guard lines.count > collapsedLineLimit else { return text }
        return lines.prefix(collapsedLineLimit).joined(separator: "\n")
    }

    // MARK: - HTTP

    private var httpContent: some View {
        let parsed = parseHTTP()

        return VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
            HStack(spacing: InspectorTheme.Spacing.sm) {
                highlightableText(parsed.method, color: InspectorTheme.Colors.methodColor(parsed.method), bold: true)
                highlightableText(parsed.path, color: InspectorTheme.Colors.textPrimary)
                Spacer()
                Text(parsed.httpVersion)
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }

            if !parsed.headers.isEmpty {
                ForEach(Array(parsed.headers.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                    HStack(alignment: .top, spacing: 0) {
                        highlightableText("\(key): ", color: InspectorTheme.Colors.syntaxKey)
                        highlightableText(value, color: InspectorTheme.Colors.textPrimary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func highlightableText(_ text: String, color: Color, bold: Bool = false) -> some View {
        if isSearching {
            HighlightedText(text: text, query: searchQuery, baseColor: color)
                .font(InspectorTheme.Typography.code)
                .fontWeight(bold ? .bold : .regular)
        } else {
            Text(text)
                .font(InspectorTheme.Typography.code)
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(color)
                .textSelection(.enabled)
        }
    }

    // MARK: - Expand

    private var expandButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
        } label: {
            HStack(spacing: InspectorTheme.Spacing.xs) {
                Text(isExpanded ? "Collapse" : "Show all \(lineCount) lines")
                    .font(InspectorTheme.Typography.detail)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(InspectorTheme.Typography.detail)
            }
            .foregroundStyle(InspectorTheme.Colors.accent)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - HTTP Parser

    private func parseHTTP() -> (method: String, path: String, httpVersion: String, headers: [String: String]) {
        let lines = text.split(whereSeparator: \.isNewline)
        guard let requestLine = lines.first else { return ("", "", "", [:]) }

        let parts = requestLine.split(separator: " ")
        let method = parts.first.map(String.init) ?? ""
        let path = parts.dropFirst().first.map(String.init) ?? ""
        let httpVersion = parts.dropFirst(2).first.map(String.init) ?? "HTTP/1.1"

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  let separatorIndex = trimmed.firstIndex(of: ":") else { continue }
            let key = String(trimmed[..<separatorIndex])
            let value = String(trimmed[trimmed.index(after: separatorIndex)...]).trimmingCharacters(in: .whitespaces)
            headers[key] = value
        }

        return (method, path, httpVersion, headers)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Plain Text") {
    ScrollView { TextRenderer(text: MockText.short).padding() }
        .inspectorBackground()
}

#Preview("Plain Text - Long") {
    ScrollView { TextRenderer(text: MockText.long).padding() }
        .inspectorBackground()
}

#Preview("Plain Text - Search") {
    ScrollView { TextRenderer(text: MockText.long, searchQuery: "line").padding() }
        .inspectorBackground()
}

#Preview("HTTP") {
    ScrollView { TextRenderer(text: MockHTTP.postRequest, language: .http).padding() }
        .inspectorBackground()
}

#Preview("HTTP - Search") {
    ScrollView { TextRenderer(text: MockHTTP.postRequest, language: .http, searchQuery: "json").padding() }
        .inspectorBackground()
}
#endif
