import SwiftUI

/// Renders JSON with syntax highlighting, collapsible nodes, search, and expand/collapse all.
struct JSONRenderer: View {
    let jsonText: String
    var searchQuery: String = ""
    var collapseAll: Bool = false

    @State private var collapsedPaths: Set<String>

    private let parsed: ParsedJSON
    private let allCollapsiblePaths: Set<String>

    init(jsonText: String, searchQuery: String = "", collapseAll: Bool = false, initialCollapsed: Set<String> = []) {
        self.jsonText = jsonText
        self.searchQuery = searchQuery
        self.collapseAll = collapseAll
        let result = Self.parse(jsonText)
        self.parsed = result
        self._collapsedPaths = State(initialValue: initialCollapsed)
        self.allCollapsiblePaths = Self.collectCollapsiblePaths(result.value, path: "root")
    }

    var body: some View {
        if let json = parsed.value {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    JSONNode(
                        value: json,
                        level: 0,
                        path: "root",
                        searchQuery: searchQuery,
                        collapsedPaths: $collapsedPaths
                    )
                }
            }
            .onChange(of: collapseAll) {
                withAnimation(.easeOut(duration: 0.2)) {
                    if collapseAll {
                        collapsedPaths = allCollapsiblePaths
                    } else {
                        collapsedPaths.removeAll()
                    }
                }
            }
        } else {
            invalidJSONView
        }
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

    /// Recursively collects paths of all objects/arrays that can be collapsed.
    private static func collectCollapsiblePaths(_ value: Any?, path: String) -> Set<String> {
        guard let value else { return [] }
        var paths = Set<String>()

        if let dict = value as? [String: Any], dict.count > 1 {
            paths.insert(path)
            for (key, val) in dict {
                paths.formUnion(collectCollapsiblePaths(val, path: "\(path).\(key)"))
            }
        } else if let array = value as? [Any], array.count > 1 {
            paths.insert(path)
            for (index, item) in array.enumerated() {
                paths.formUnion(collectCollapsiblePaths(item, path: "\(path)[\(index)]"))
            }
        }

        return paths
    }

    private var invalidJSONView: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
            HStack(spacing: InspectorTheme.Spacing.xs) {
                Image(systemName: "exclamationmark.triangle")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.warning)
                Text("Invalid JSON")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.warning)
            }
            Text(jsonText)
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                .textSelection(.enabled)
        }
    }
}

// MARK: - JSON Node (recursive)

private struct JSONNode: View {
    let value: Any
    let level: Int
    let path: String
    var key: String?
    var isLast: Bool = true
    var searchQuery: String = ""
    @Binding var collapsedPaths: Set<String>

    private var isCollapsed: Bool { collapsedPaths.contains(path) }
    private let indent: CGFloat = 16

    private var isSearching: Bool { !searchQuery.isEmpty }
    private var query: String { searchQuery.lowercased() }

    var body: some View {
        if level > 8 {
            truncatedView
        } else if let dict = value as? [String: Any] {
            objectView(dict)
        } else if let array = value as? [Any] {
            arrayView(array)
        } else {
            primitiveView
        }
    }

    // MARK: - Object

    @ViewBuilder
    private func objectView(_ dict: [String: Any]) -> some View {
        let sortedKeys = dict.keys.sorted()
        let canCollapse = dict.count > 1

        HStack(spacing: 0) {
            keyLabel
            if canCollapse { collapseToggle }
            Text(isCollapsed ? "{\(dict.count) keys}" : "{")
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(isCollapsed ? InspectorTheme.Colors.textTertiary : InspectorTheme.Colors.textPrimary)
            if !isCollapsed { Spacer(minLength: 0) }
            if isCollapsed {
                comma
                Spacer(minLength: 0)
            }
        }
        .padding(.leading, CGFloat(level) * indent)

        if !isCollapsed {
            ForEach(Array(sortedKeys.enumerated()), id: \.element) { index, dictKey in
                JSONNode(
                    value: dict[dictKey] ?? NSNull(),
                    level: level + 1,
                    path: "\(path).\(dictKey)",
                    key: dictKey,
                    isLast: index == sortedKeys.count - 1,
                    searchQuery: searchQuery,
                    collapsedPaths: $collapsedPaths
                )
            }

            HStack(spacing: 0) {
                Text("}")
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                comma
                Spacer(minLength: 0)
            }
            .padding(.leading, CGFloat(level) * indent)
        }
    }

    // MARK: - Array

    @ViewBuilder
    private func arrayView(_ array: [Any]) -> some View {
        let canCollapse = array.count > 1
        let maxItems = 100

        HStack(spacing: 0) {
            keyLabel
            if canCollapse { collapseToggle }
            Text(isCollapsed ? "[\(array.count) items]" : "[")
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(isCollapsed ? InspectorTheme.Colors.textTertiary : InspectorTheme.Colors.textPrimary)
            if !isCollapsed { Spacer(minLength: 0) }
            if isCollapsed {
                comma
                Spacer(minLength: 0)
            }
        }
        .padding(.leading, CGFloat(level) * indent)

        if !isCollapsed {
            let itemsToShow = min(array.count, maxItems)
            ForEach(0..<itemsToShow, id: \.self) { index in
                JSONNode(
                    value: array[index],
                    level: level + 1,
                    path: "\(path)[\(index)]",
                    isLast: index == itemsToShow - 1 && array.count <= maxItems,
                    searchQuery: searchQuery,
                    collapsedPaths: $collapsedPaths
                )
            }

            if array.count > maxItems {
                Text("... \(array.count - maxItems) more items")
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
                    .italic()
                    .padding(.leading, CGFloat(level + 1) * indent)
            }

            HStack(spacing: 0) {
                Text("]")
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                comma
                Spacer(minLength: 0)
            }
            .padding(.leading, CGFloat(level) * indent)
        }
    }

    // MARK: - Primitive

    private var primitiveView: some View {
        HStack(spacing: 0) {
            keyLabel

            if let str = value as? String {
                highlightedText("\"\(str)\"", color: InspectorTheme.Colors.syntaxString)
            } else if let num = value as? NSNumber {
                if num.isBool {
                    highlightedText(
                        num.boolValue ? "true" : "false",
                        color: InspectorTheme.Colors.syntaxBool
                    )
                } else {
                    highlightedText("\(num)", color: InspectorTheme.Colors.syntaxNumber)
                }
            } else if value is NSNull {
                highlightedText("null", color: InspectorTheme.Colors.syntaxNull)
            }
            comma
            Spacer(minLength: 0)
        }
        .padding(.leading, CGFloat(level) * indent)
        .textSelection(.enabled)
    }

    // MARK: - Truncated

    private var truncatedView: some View {
        HStack(spacing: 0) {
            keyLabel
            Text("...")
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
                .italic()
            Spacer(minLength: 0)
        }
        .padding(.leading, CGFloat(level) * indent)
    }

    // MARK: - Shared Components

    @ViewBuilder
    private var keyLabel: some View {
        if let key {
            if isSearching && key.lowercased().contains(query) {
                highlightedText("\"\(key)\": ", color: InspectorTheme.Colors.syntaxKey, bold: true)
            } else {
                Text("\"\(key)\": ")
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.syntaxKey)
            }
        }
    }

    @ViewBuilder
    private var comma: some View {
        if !isLast {
            Text(",")
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
    }

    private var collapseToggle: some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                if isCollapsed {
                    collapsedPaths.remove(path)
                } else {
                    collapsedPaths.insert(path)
                }
            }
        } label: {
            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
                .frame(width: 16, height: 16)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search Highlight

    @ViewBuilder
    private func highlightedText(_ text: String, color: Color, bold: Bool = false) -> some View {
        if isSearching && text.lowercased().contains(query) {
            HighlightedText(text: text, query: searchQuery, baseColor: color)
                .font(InspectorTheme.Typography.code)
                .fontWeight(bold ? .medium : .regular)
        } else {
            Text(text)
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(color)
                .fontWeight(bold ? .medium : .regular)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("JSON - All Types") {
    ScrollView { JSONRenderer(jsonText: MockJSON.allTypes).padding() }
        .inspectorBackground()
}

#Preview("JSON - Large Array") {
    ScrollView { JSONRenderer(jsonText: MockJSON.largeArray).padding() }
        .inspectorBackground()
}

#Preview("JSON - Deep Nesting") {
    ScrollView { JSONRenderer(jsonText: MockJSON.deepNesting).padding() }
        .inspectorBackground()
}

#Preview("JSON - Empty Structures") {
    ScrollView { JSONRenderer(jsonText: MockJSON.emptyStructures).padding() }
        .inspectorBackground()
}

#Preview("JSON - Collapsed") {
    ScrollView {
        JSONRenderer(jsonText: MockJSON.largeArray, initialCollapsed: ["root.items"])
            .padding()
    }
    .inspectorBackground()
}

#Preview("JSON - Search Highlight") {
    ScrollView {
        JSONRenderer(jsonText: MockJSON.nested, searchQuery: "item")
            .padding()
    }
    .inspectorBackground()
}

#Preview("JSON - Invalid") {
    ScrollView { JSONRenderer(jsonText: MockJSON.invalid).padding() }
        .inspectorBackground()
}
#endif
