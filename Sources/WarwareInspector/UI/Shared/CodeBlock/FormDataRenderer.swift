import SwiftUI

/// Renders URL-encoded form data (key=value&key2=value2) as a key-value table.
struct FormDataRenderer: View {
    let text: String
    var searchQuery: String = ""

    private var parameters: [(key: String, value: String)] {
        text.components(separatedBy: "&").compactMap { pair in
            let parts = pair.components(separatedBy: "=")
            guard let key = parts.first else { return nil }
            let value = parts.dropFirst().joined(separator: "=")
            let decodedKey = key.removingPercentEncoding ?? key
            let decodedValue = value.removingPercentEncoding ?? value
            return (decodedKey, decodedValue)
        }
    }

    private var isSearching: Bool { !searchQuery.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
            ForEach(Array(parameters.enumerated()), id: \.offset) { index, param in
                HStack(alignment: .top, spacing: 0) {
                    Text("\(index + 1)")
                        .font(InspectorTheme.Typography.codeSmall)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                        .frame(width: 24, alignment: .trailing)
                        .padding(.trailing, InspectorTheme.Spacing.sm)

                    if isSearching {
                        HighlightedText(text: param.key, query: searchQuery, baseColor: InspectorTheme.Colors.syntaxKey)
                            .font(InspectorTheme.Typography.code)
                    } else {
                        Text(param.key)
                            .font(InspectorTheme.Typography.code)
                            .foregroundStyle(InspectorTheme.Colors.syntaxKey)
                    }

                    Text(" = ")
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)

                    if isSearching {
                        HighlightedText(text: param.value, query: searchQuery, baseColor: InspectorTheme.Colors.syntaxString)
                            .font(InspectorTheme.Typography.code)
                    } else {
                        Text(param.value)
                            .font(InspectorTheme.Typography.code)
                            .foregroundStyle(InspectorTheme.Colors.syntaxString)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Form - Simple") {
    ScrollView {
        FormDataRenderer(text: "name=John+Doe&email=john%40example.com&age=30")
            .padding()
    }
    .inspectorBackground()
}

#Preview("Form - OAuth") {
    ScrollView {
        FormDataRenderer(text: "grant_type=authorization_code&code=abc123&redirect_uri=https%3A%2F%2Fapp.example.com%2Fcallback&client_id=my-app")
            .padding()
    }
    .inspectorBackground()
}
#endif
