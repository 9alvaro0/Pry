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

    private var plainTextContent: some View {
        let lines = text.components(separatedBy: .newlines)
        let visibleLines = isExpanded ? lines : Array(lines.prefix(collapsedLineLimit))
        let gutterWidth = gutterWidth(for: lines.count)

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(visibleLines.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .top, spacing: 0) {
                    Text("\(index + 1)")
                        .font(InspectorTheme.Typography.codeSmall)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                        .frame(width: gutterWidth, alignment: .trailing)
                        .padding(.trailing, InspectorTheme.Spacing.sm)

                    if isSearching {
                        HighlightedText(
                            text: line.isEmpty ? " " : line,
                            query: searchQuery,
                            baseColor: InspectorTheme.Colors.textPrimary
                        )
                        .font(InspectorTheme.Typography.code)
                    } else {
                        Text(line.isEmpty ? " " : line)
                            .font(InspectorTheme.Typography.code)
                            .foregroundStyle(InspectorTheme.Colors.textPrimary)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }

    private func gutterWidth(for totalLines: Int) -> CGFloat {
        let digits = String(totalLines).count
        return CGFloat(digits) * 8 + 4
    }

    // MARK: - HTTP

    private var httpContent: some View {
        let parsed = parseHTTP()
        let totalLines = 1 + parsed.headers.count
        let gutter = gutterWidth(for: totalLines)

        return VStack(alignment: .leading, spacing: 0) {
            // Line 1: request line
            HStack(alignment: .top, spacing: 0) {
                lineNumber(1, gutterWidth: gutter)
                HStack(spacing: InspectorTheme.Spacing.sm) {
                    highlightableText(parsed.method, color: InspectorTheme.Colors.methodColor(parsed.method), bold: true)
                    highlightableText(parsed.path, color: InspectorTheme.Colors.textPrimary)
                    Spacer()
                    Text(parsed.httpVersion)
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }
            }

            // Headers
            ForEach(Array(parsed.headers.sorted(by: { $0.key < $1.key }).enumerated()), id: \.element.key) { index, header in
                HStack(alignment: .top, spacing: 0) {
                    lineNumber(index + 2, gutterWidth: gutter)
                    highlightableText("\(header.key): ", color: InspectorTheme.Colors.syntaxKey)
                    highlightableText(header.value, color: InspectorTheme.Colors.textPrimary)
                }
            }
        }
    }

    private func lineNumber(_ number: Int, gutterWidth: CGFloat) -> some View {
        Text("\(number)")
            .font(InspectorTheme.Typography.codeSmall)
            .foregroundStyle(InspectorTheme.Colors.textTertiary)
            .frame(width: gutterWidth, alignment: .trailing)
            .padding(.trailing, InspectorTheme.Spacing.sm)
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
            withAnimation(.easeInOut(duration: InspectorTheme.Animation.standard)) { isExpanded.toggle() }
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
