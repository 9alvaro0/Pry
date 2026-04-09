import SwiftUI

/// Renders URL-encoded form data (key=value&key2=value2) as a key-value table.
@_spi(PryPro) public struct FormDataRenderer: View {
    @_spi(PryPro) public let text: String
    @_spi(PryPro) public var searchQuery: String = ""

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

    @_spi(PryPro) public var body: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            ForEach(Array(parameters.enumerated()), id: \.offset) { index, param in
                HStack(alignment: .top, spacing: 0) {
                    Text("\(index + 1)")
                        .font(PryTheme.Typography.codeSmall)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                        .frame(width: PryTheme.Size.formKeyWidth, alignment: .trailing)
                        .padding(.trailing, PryTheme.Spacing.sm)

                    if isSearching {
                        HighlightedText(text: param.key, query: searchQuery, baseColor: PryTheme.Colors.syntaxKey)
                            .font(PryTheme.Typography.code)
                    } else {
                        Text(param.key)
                            .font(PryTheme.Typography.code)
                            .foregroundStyle(PryTheme.Colors.syntaxKey)
                    }

                    Text(" = ")
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.textTertiary)

                    if isSearching {
                        HighlightedText(text: param.value, query: searchQuery, baseColor: PryTheme.Colors.syntaxString)
                            .font(PryTheme.Typography.code)
                    } else {
                        Text(param.value)
                            .font(PryTheme.Typography.code)
                            .foregroundStyle(PryTheme.Colors.syntaxString)
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
    .pryBackground()
}

#Preview("Form - OAuth") {
    ScrollView {
        FormDataRenderer(text: "grant_type=authorization_code&code=abc123&redirect_uri=https%3A%2F%2Fapp.example.com%2Fcallback&client_id=my-app")
            .padding()
    }
    .pryBackground()
}
#endif
