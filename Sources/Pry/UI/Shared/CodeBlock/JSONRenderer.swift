import SwiftUI

/// Renders JSON with syntax highlighting, collapsible nodes, search, line numbers, and expand/collapse all.
package struct JSONRenderer: View {
    package let jsonText: String
    package var searchQuery: String = ""
    package var collapseAll: Bool = false

    @State private var collapsedPaths: Set<String>

    private let parsed: ParsedJSON
    private let allCollapsiblePaths: Set<String>

    package init(jsonText: String, searchQuery: String = "", collapseAll: Bool = false, initialCollapsed: Set<String> = []) {
        self.jsonText = jsonText
        self.searchQuery = searchQuery
        self.collapseAll = collapseAll
        let result = Self.parse(jsonText)
        self.parsed = result
        self._collapsedPaths = State(initialValue: initialCollapsed)
        self.allCollapsiblePaths = Self.collectCollapsiblePaths(result.value, path: "root")
    }

    /// All lines with absolute numbers (as if fully expanded).
    private var allLines: [JSONLine] {
        guard let value = parsed.value else { return [] }
        var lines: [JSONLine] = []
        var lineNum = 1
        flattenAll(value, path: "root", key: nil, level: 0, isLast: true, lineNum: &lineNum, into: &lines)
        return lines
    }

    /// Only the visible lines (respecting collapsed state), keeping original line numbers.
    private var visibleLines: [JSONLine] {
        let all = allLines
        var visible: [JSONLine] = []
        var skipPaths: Set<String> = []

        for line in all {
            // Skip children and closing brace of collapsed nodes
            if !skipPaths.isEmpty {
                // Is this a closing brace for a collapsed path?
                let isClosingOfCollapsed: Bool = {
                    if case .closeBrace = line.content {
                        return skipPaths.contains(line.path)
                    }
                    return false
                }()

                if isClosingOfCollapsed {
                    skipPaths.remove(line.path)
                    continue
                }

                // Is this a child of any collapsed path?
                let isChild = skipPaths.contains { line.path.hasPrefix($0 + ".") || line.path.hasPrefix($0 + "[") }
                if isChild { continue }
            }

            // Check if this line starts a collapsed section
            if line.isCollapsible, collapsedPaths.contains(line.path),
               case .openBrace = line.content {
                var collapsed = line
                if case .openBrace("{") = line.content {
                    collapsed.content = .collapsedObject(line.childCount)
                    collapsed.hasComma = line.closingHasComma
                } else if case .openBrace("[") = line.content {
                    collapsed.content = .collapsedArray(line.childCount)
                    collapsed.hasComma = line.closingHasComma
                }
                visible.append(collapsed)
                skipPaths.insert(line.path)
            } else {
                visible.append(line)
            }
        }

        return visible
    }

    private var gutterWidth: CGFloat {
        let maxNum = allLines.last?.lineNumber ?? 1
        let digits = String(maxNum).count
        return CGFloat(max(digits, 2)) * 8 + 4
    }

    package var body: some View {
        if parsed.value != nil {
            let lines = visibleLines

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(lines, id: \.lineNumber) { line in
                        HStack(alignment: .top, spacing: 0) {
                            Text("\(line.lineNumber)")
                                .font(PryTheme.Typography.codeSmall)
                                .foregroundStyle(PryTheme.Colors.textTertiary)
                                .frame(width: gutterWidth, alignment: .trailing)
                                .padding(.trailing, PryTheme.Spacing.sm)

                            lineView(line)
                        }
                    }
                }
            }
            .onChange(of: collapseAll) {
                withAnimation(.easeOut(duration: PryTheme.Animation.standard)) {
                    collapsedPaths = collapseAll ? allCollapsiblePaths : []
                }
            }
        } else {
            invalidJSONView
        }
    }

    // MARK: - Line Rendering

    @ViewBuilder
    private func lineView(_ line: JSONLine) -> some View {
        HStack(spacing: 0) {
            // Indent
            if line.level > 0 {
                Color.clear
                    .frame(width: CGFloat(line.level) * PryTheme.Size.toggleIcon)
            }

            // Collapse toggle
            if line.isCollapsible {
                collapseButton(for: line.path)
            }

            // Key
            if let key = line.key {
                highlightable("\"\(key)\": ", color: PryTheme.Colors.syntaxKey)
            }

            // Content
            switch line.content {
            case .openBrace(let brace):
                Text(brace)
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textPrimary)

            case .closeBrace(let brace):
                Text(brace)
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textPrimary)

            case .collapsedObject(let count):
                Text("{\(count) keys}")
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textTertiary)

            case .collapsedArray(let count):
                Text("[\(count) items]")
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textTertiary)

            case .string(let value):
                highlightable("\"\(Self.escapeJSONString(value))\"", color: PryTheme.Colors.syntaxString)

            case .number(let value):
                highlightable(value, color: PryTheme.Colors.syntaxNumber)

            case .bool(let value):
                highlightable(value ? "true" : "false", color: PryTheme.Colors.syntaxBool)

            case .null:
                highlightable("null", color: PryTheme.Colors.syntaxNull)

            case .truncated:
                Text("...")
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
                    .italic()

            case .overflow(let remaining):
                Text("... \(remaining) more items")
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
                    .italic()
            }

            // Comma
            if line.hasComma {
                Text(",")
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }

            Spacer(minLength: 0)
        }
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func highlightable(_ text: String, color: Color) -> some View {
        if !searchQuery.isEmpty {
            HighlightedText(text: text, query: searchQuery, baseColor: color)
                .font(PryTheme.Typography.code)
        } else {
            Text(text)
                .font(PryTheme.Typography.code)
                .foregroundStyle(color)
        }
    }

    private func collapseButton(for path: String) -> some View {
        let collapsed = collapsedPaths.contains(path)
        return Button {
            withAnimation(.easeOut(duration: PryTheme.Animation.quick)) {
                if collapsed { collapsedPaths.remove(path) }
                else { collapsedPaths.insert(path) }
            }
        } label: {
            Image(systemName: collapsed ? "chevron.right" : "chevron.down")
                .font(PryTheme.Typography.badgeText)
                .foregroundStyle(PryTheme.Colors.textTertiary)
                .frame(width: PryTheme.Size.toggleIcon, height: PryTheme.Size.toggleIcon)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Flatten JSON to Lines (always fully expanded, with absolute line numbers)

    private func flattenAll(
        _ value: Any,
        path: String,
        key: String?,
        level: Int,
        isLast: Bool,
        lineNum: inout Int,
        into lines: inout [JSONLine]
    ) {
        guard level <= 8 else {
            lines.append(JSONLine(lineNumber: lineNum, level: level, key: key, content: .truncated, hasComma: !isLast, path: path))
            lineNum += 1
            return
        }

        if let dict = value as? [String: Any] {
            let canCollapse = !dict.isEmpty
            let openLine = lineNum
            lineNum += 1

            lines.append(JSONLine(
                lineNumber: openLine, level: level, key: key,
                content: .openBrace("{"),
                hasComma: false, path: path, isCollapsible: canCollapse,
                childCount: dict.count
            ))

            let sortedKeys = dict.keys.sorted()
            for (index, dictKey) in sortedKeys.enumerated() {
                flattenAll(
                    dict[dictKey] ?? NSNull(),
                    path: "\(path).\(dictKey)",
                    key: dictKey, level: level + 1,
                    isLast: index == sortedKeys.count - 1,
                    lineNum: &lineNum, into: &lines
                )
            }

            let closingComma = !isLast
            lines.append(JSONLine(
                lineNumber: lineNum, level: level, key: nil,
                content: .closeBrace("}"),
                hasComma: closingComma, path: path
            ))
            // Store closing comma info on the open brace for collapsed rendering
            if let openIndex = lines.firstIndex(where: { $0.lineNumber == openLine && $0.path == path }) {
                lines[openIndex].closingHasComma = closingComma
            }
            lineNum += 1

        } else if let array = value as? [Any] {
            let canCollapse = !array.isEmpty
            let maxItems = 100
            let openLine = lineNum
            lineNum += 1

            lines.append(JSONLine(
                lineNumber: openLine, level: level, key: key,
                content: .openBrace("["),
                hasComma: false, path: path, isCollapsible: canCollapse,
                childCount: array.count
            ))

            let itemCount = min(array.count, maxItems)
            for index in 0..<itemCount {
                flattenAll(
                    array[index],
                    path: "\(path)[\(index)]",
                    key: nil, level: level + 1,
                    isLast: index == itemCount - 1 && array.count <= maxItems,
                    lineNum: &lineNum, into: &lines
                )
            }

            if array.count > maxItems {
                lines.append(JSONLine(
                    lineNumber: lineNum, level: level + 1, key: nil,
                    content: .overflow(array.count - maxItems),
                    hasComma: false, path: path
                ))
                lineNum += 1
            }

            let closingComma = !isLast
            lines.append(JSONLine(
                lineNumber: lineNum, level: level, key: nil,
                content: .closeBrace("]"),
                hasComma: closingComma, path: path
            ))
            if let openIndex = lines.firstIndex(where: { $0.lineNumber == openLine && $0.path == path }) {
                lines[openIndex].closingHasComma = closingComma
            }
            lineNum += 1

        } else if let str = value as? String {
            lines.append(JSONLine(lineNumber: lineNum, level: level, key: key, content: .string(str), hasComma: !isLast, path: path))
            lineNum += 1
        } else if let num = value as? NSNumber {
            if num.isBool {
                lines.append(JSONLine(lineNumber: lineNum, level: level, key: key, content: .bool(num.boolValue), hasComma: !isLast, path: path))
            } else {
                lines.append(JSONLine(lineNumber: lineNum, level: level, key: key, content: .number("\(num)"), hasComma: !isLast, path: path))
            }
            lineNum += 1
        } else if value is NSNull {
            lines.append(JSONLine(lineNumber: lineNum, level: level, key: key, content: .null, hasComma: !isLast, path: path))
            lineNum += 1
        }
    }

    // MARK: - String Escaping

    /// Escapes control characters and quotes so JSON string values render on a single line.
    /// JSONSerialization decodes `\n`, `\t`, etc. into actual control characters, which
    /// would otherwise break line numbering and indentation when rendered by SwiftUI's Text.
    private static func escapeJSONString(_ s: String) -> String {
        var result = ""
        result.reserveCapacity(s.count)
        for scalar in s.unicodeScalars {
            switch scalar {
            case "\\": result += "\\\\"
            case "\"": result += "\\\""
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            case "\u{08}": result += "\\b"
            case "\u{0C}": result += "\\f"
            default:
                if scalar.value < 0x20 {
                    result += String(format: "\\u%04x", scalar.value)
                } else {
                    result.unicodeScalars.append(scalar)
                }
            }
        }
        return result
    }

    // MARK: - Parsing

    private struct ParsedJSON {
        let value: Any?
    }

    private static func parse(_ text: String) -> ParsedJSON {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let data = trimmed.data(using: .utf8),
           let result = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) {
            return ParsedJSON(value: result)
        }

        let fixed = trimmed
            .replacingOccurrences(of: ",\\s*}", with: "}", options: .regularExpression)
            .replacingOccurrences(of: ",\\s*]", with: "]", options: .regularExpression)

        if let data = fixed.data(using: .utf8),
           let result = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) {
            return ParsedJSON(value: result)
        }

        return ParsedJSON(value: nil)
    }

    private static func collectCollapsiblePaths(_ value: Any?, path: String) -> Set<String> {
        guard let value else { return [] }
        var paths = Set<String>()

        if let dict = value as? [String: Any], !dict.isEmpty {
            paths.insert(path)
            for (key, val) in dict { paths.formUnion(collectCollapsiblePaths(val, path: "\(path).\(key)")) }
        } else if let array = value as? [Any], !array.isEmpty {
            paths.insert(path)
            for (i, item) in array.enumerated() { paths.formUnion(collectCollapsiblePaths(item, path: "\(path)[\(i)]")) }
        }

        return paths
    }

    private var invalidJSONView: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            HStack(spacing: PryTheme.Spacing.xs) {
                Image(systemName: "exclamationmark.triangle")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.warning)
                Text("Invalid JSON")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.warning)
            }
            Text(jsonText)
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .textSelection(.enabled)
        }
    }
}

// MARK: - JSON Line Model

private struct JSONLine {
    let lineNumber: Int
    let level: Int
    let key: String?
    var content: Content
    var hasComma: Bool
    let path: String
    var isCollapsible: Bool = false
    var childCount: Int = 0
    var closingHasComma: Bool = false

    enum Content {
        case openBrace(String)
        case closeBrace(String)
        case collapsedObject(Int)
        case collapsedArray(Int)
        case string(String)
        case number(String)
        case bool(Bool)
        case null
        case truncated
        case overflow(Int)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("JSON - All Types") {
    ScrollView { JSONRenderer(jsonText: MockJSON.allTypes).padding() }
        .pryBackground()
}

#Preview("JSON - Large Array") {
    ScrollView { JSONRenderer(jsonText: MockJSON.largeArray).padding() }
        .pryBackground()
}

#Preview("JSON - Deep Nesting") {
    ScrollView { JSONRenderer(jsonText: MockJSON.deepNesting).padding() }
        .pryBackground()
}

#Preview("JSON - Empty Structures") {
    ScrollView { JSONRenderer(jsonText: MockJSON.emptyStructures).padding() }
        .pryBackground()
}

#Preview("JSON - Collapsed") {
    ScrollView {
        JSONRenderer(jsonText: MockJSON.largeArray, initialCollapsed: ["root.items"])
            .padding()
    }
    .pryBackground()
}

#Preview("JSON - Search Highlight") {
    ScrollView {
        JSONRenderer(jsonText: MockJSON.nested, searchQuery: "item")
            .padding()
    }
    .pryBackground()
}

#endif
