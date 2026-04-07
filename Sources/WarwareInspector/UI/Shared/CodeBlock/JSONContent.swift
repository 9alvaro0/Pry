import SwiftUI

struct JSONContentView: View {
    let value: Any
    let level: Int
    var key: String?
    var arrayIndex: Int?
    @Binding var collapsedKeys: Set<String>

    private var keyPath: String {
        var path = "\(level)"
        if let key { path += "-\(key)" } else { path += "-root" }
        if let index = arrayIndex { path += "-[\(index)]" }
        return path
    }

    private var isCollapsed: Bool { collapsedKeys.contains(keyPath) }
    private var indentWidth: CGFloat { CGFloat(level) * InspectorTheme.Spacing.md }

    var body: some View {
        HStack(alignment: .top, spacing: InspectorTheme.Spacing.xs) {
            if level > 0 {
                Rectangle().fill(.clear).frame(width: indentWidth, height: 1)
            }
            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                renderValue()
            }
            Spacer(minLength: 0)
        }
        .textSelection(.enabled)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func renderValue() -> some View {
        if level > 6 {
            HStack(alignment: .top, spacing: InspectorTheme.Spacing.xs) {
                if let key {
                    Text("\"\(key)\":")
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.syntaxKey)
                        .fontWeight(.medium)
                }
                Text("...")
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.syntaxNull)
                    .italic()
                Spacer(minLength: 0)
            }
        } else if let dict = value as? [String: Any] {
            renderObject(dict)
        } else if let array = value as? [Any] {
            renderArray(array)
        } else {
            renderPrimitive()
        }
    }

    @ViewBuilder
    private func renderObject(_ dict: [String: Any]) -> some View {
        HStack(alignment: .top, spacing: InspectorTheme.Spacing.xs) {
            if let key {
                Text("\"\(key)\":")
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.syntaxKey)
                    .fontWeight(.medium)
            }
            if dict.count > 3 && level < 4 {
                collapseButton
            }
            Text("{")
                .font(InspectorTheme.Typography.code)
            if isCollapsed && dict.count > 3 {
                Text("...}")
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.syntaxNull)
            }
            Spacer(minLength: 0)
        }

        if !isCollapsed || dict.count <= 3 {
            ForEach(Array(dict.keys.sorted()), id: \.self) { dictKey in
                JSONContentView(
                    value: dict[dictKey] ?? NSNull(),
                    level: level + 1,
                    key: dictKey,
                    collapsedKeys: $collapsedKeys
                )
            }
            closingBrace("}")
        }
    }

    @ViewBuilder
    private func renderArray(_ array: [Any]) -> some View {
        HStack(alignment: .top, spacing: InspectorTheme.Spacing.xs) {
            if let key {
                Text("\"\(key)\":")
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.syntaxKey)
                    .fontWeight(.medium)
            }
            if array.count > 2 && level < 4 {
                collapseButton
            }
            Text("[")
                .font(InspectorTheme.Typography.code)
            if isCollapsed && array.count > 2 {
                Text("...]")
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.syntaxNull)
            }
            Spacer(minLength: 0)
        }

        if !isCollapsed || array.count <= 2 {
            let maxItems = 50
            ForEach(Array(array.enumerated()).prefix(maxItems), id: \.offset) { index, item in
                JSONContentView(
                    value: item,
                    level: level + 1,
                    arrayIndex: index,
                    collapsedKeys: $collapsedKeys
                )
            }
            if array.count > maxItems {
                HStack {
                    Rectangle().fill(.clear).frame(width: indentWidth + InspectorTheme.Spacing.lg, height: 1)
                    Text("... \(array.count - maxItems) more items")
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.syntaxNull)
                        .italic()
                }
            }
            closingBrace("]")
        }
    }

    @ViewBuilder
    private func renderPrimitive() -> some View {
        HStack(alignment: .top, spacing: InspectorTheme.Spacing.xs) {
            if let key {
                Text("\"\(key)\":")
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.syntaxKey)
                    .fontWeight(.medium)
            }
            if let str = value as? String {
                Text("\"\(str)\"")
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.syntaxString)
            } else if let num = value as? NSNumber {
                if num.isBool {
                    Text(num.boolValue ? "true" : "false")
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.syntaxBool)
                } else {
                    Text("\(num)")
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.syntaxNumber)
                }
            } else if value is NSNull {
                Text("null")
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.syntaxNull)
            }
            Spacer(minLength: 0)
        }
    }

    private var collapseButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                if isCollapsed {
                    collapsedKeys.remove(keyPath)
                } else {
                    collapsedKeys.insert(keyPath)
                }
            }
        } label: {
            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)
                .frame(width: InspectorTheme.Size.iconMedium, height: InspectorTheme.Size.iconMedium)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func closingBrace(_ brace: String) -> some View {
        HStack(alignment: .top) {
            if level > 0 {
                Rectangle().fill(.clear).frame(width: indentWidth, height: 1)
            }
            Text(brace)
                .font(InspectorTheme.Typography.code)
            Spacer(minLength: 0)
        }
    }
}
