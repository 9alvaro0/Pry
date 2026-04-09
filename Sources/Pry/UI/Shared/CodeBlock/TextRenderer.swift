import SwiftUI

/// Renders plain text and HTTP content with expand/collapse and search highlight support.
package struct TextRenderer: View {
    package let text: String
    package var language: ContentLanguage = .text
    package var searchQuery: String = ""

    @State private var isExpanded = false

    private let collapsedLineLimit = 12

    private var lineCount: Int {
        text.components(separatedBy: .newlines).count
    }

    private var isLong: Bool {
        lineCount > collapsedLineLimit
    }

    private var isSearching: Bool { !searchQuery.isEmpty }

    package var body: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
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
                        .font(PryTheme.Typography.codeSmall)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                        .frame(width: gutterWidth, alignment: .trailing)
                        .padding(.trailing, PryTheme.Spacing.sm)

                    if isSearching {
                        HighlightedText(
                            text: line.isEmpty ? " " : line,
                            query: searchQuery,
                            baseColor: PryTheme.Colors.textPrimary
                        )
                        .font(PryTheme.Typography.code)
                    } else {
                        Text(line.isEmpty ? " " : line)
                            .font(PryTheme.Typography.code)
                            .foregroundStyle(PryTheme.Colors.textPrimary)
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
                HStack(spacing: PryTheme.Spacing.sm) {
                    highlightableText(parsed.method, color: PryTheme.Colors.methodColor(parsed.method), bold: true)
                    highlightableText(parsed.path, color: PryTheme.Colors.textPrimary)
                    Spacer()
                    Text(parsed.httpVersion)
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }
            }

            // Headers
            ForEach(Array(parsed.headers.sorted(by: { $0.key < $1.key }).enumerated()), id: \.element.key) { index, header in
                HStack(alignment: .top, spacing: 0) {
                    lineNumber(index + 2, gutterWidth: gutter)
                    highlightableText("\(header.key): ", color: PryTheme.Colors.syntaxKey)
                    highlightableText(header.value, color: PryTheme.Colors.textPrimary)
                }
            }
        }
    }

    private func lineNumber(_ number: Int, gutterWidth: CGFloat) -> some View {
        Text("\(number)")
            .font(PryTheme.Typography.codeSmall)
            .foregroundStyle(PryTheme.Colors.textTertiary)
            .frame(width: gutterWidth, alignment: .trailing)
            .padding(.trailing, PryTheme.Spacing.sm)
    }

    @ViewBuilder
    private func highlightableText(_ text: String, color: Color, bold: Bool = false) -> some View {
        if isSearching {
            HighlightedText(text: text, query: searchQuery, baseColor: color)
                .font(PryTheme.Typography.code)
                .fontWeight(bold ? .bold : .regular)
        } else {
            Text(text)
                .font(PryTheme.Typography.code)
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(color)
                .textSelection(.enabled)
        }
    }

    // MARK: - Expand

    private var expandButton: some View {
        Button {
            withAnimation(.easeInOut(duration: PryTheme.Animation.standard)) { isExpanded.toggle() }
        } label: {
            HStack(spacing: PryTheme.Spacing.xs) {
                Text(isExpanded ? "Collapse" : "Show all \(lineCount) lines")
                    .font(PryTheme.Typography.detail)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(PryTheme.Typography.detail)
            }
            .foregroundStyle(PryTheme.Colors.accent)
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
        .pryBackground()
}

#Preview("Plain Text - Long") {
    ScrollView { TextRenderer(text: MockText.long).padding() }
        .pryBackground()
}

#Preview("Plain Text - Search") {
    ScrollView { TextRenderer(text: MockText.long, searchQuery: "line").padding() }
        .pryBackground()
}

#Preview("HTTP") {
    ScrollView { TextRenderer(text: MockHTTP.postRequest, language: .http).padding() }
        .pryBackground()
}

#Preview("HTTP - Search") {
    ScrollView { TextRenderer(text: MockHTTP.postRequest, language: .http, searchQuery: "json").padding() }
        .pryBackground()
}
#endif
