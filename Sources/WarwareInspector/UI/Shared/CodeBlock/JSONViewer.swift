import SwiftUI

struct JSONViewerView: View {
    let jsonText: String
    @State private var collapsedKeys: Set<String> = []

    private var parsedJSON: Any? {
        tryParseJSON(jsonText) ?? tryToFixJSON(jsonText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
            JSONHeaderView(jsonText: jsonText)

            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                if let json = parsedJSON {
                    JSONContentView(value: json, level: 0, collapsedKeys: $collapsedKeys)
                } else {
                    VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(InspectorTheme.Typography.detail)
                                .foregroundStyle(InspectorTheme.Colors.warning)
                            Text("Invalid JSON - showing as formatted text")
                                .font(InspectorTheme.Typography.detail)
                                .foregroundStyle(InspectorTheme.Colors.warning)
                        }
                        Text(jsonText)
                            .font(InspectorTheme.Typography.code)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .inspectorCodeBlock()
    }

    private func tryToFixJSON(_ text: String) -> Any? {
        let base = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let attempts = [
            base,
            base.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression),
            base.replacingOccurrences(of: "\\[\\s*\\]", with: "[]", options: .regularExpression),
            base.replacingOccurrences(of: "\\s*:\\s*", with: ": ", options: .regularExpression),
            base
                .replacingOccurrences(of: ",\\s*}", with: "}", options: .regularExpression)
                .replacingOccurrences(of: ",\\s*]", with: "]", options: .regularExpression)
        ]

        for candidate in attempts {
            if let json = tryParseJSON(candidate) { return json }
        }
        return nil
    }

    private func tryParseJSON(_ text: String) -> Any? {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleaned.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }
}
