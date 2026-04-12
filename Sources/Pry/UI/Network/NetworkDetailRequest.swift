import SwiftUI

/// Request tab: headers, body, query parameters.
struct NetworkDetailRequest: View {
    let entry: NetworkEntry

    private static let internalHeaders: Set<String> = ["Content-Length", "Accept-Encoding", "X-Pry-Replay"]

    private var displayHeaders: [String: String] {
        entry.requestHeaders.filter { key, _ in
            !key.hasPrefix("X-Debug-") && !Self.internalHeaders.contains(key)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headersSection
            bodySection
            queryParamsSection
        }
    }

    // MARK: - Headers

    @ViewBuilder
    private var headersSection: some View {
        let headers = displayHeaders
        if !headers.isEmpty {
            DetailSectionView(title: "Headers", collapsible: true, startCollapsed: true) {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                    ForEach(Array(headers.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        if key == "Authorization", value.count > 50 {
                            HStack(alignment: .top) {
                                Text(key)
                                    .font(PryTheme.Typography.body)
                                    .foregroundStyle(PryTheme.Colors.textSecondary)
                                Spacer(minLength: PryTheme.Spacing.sm)
                                Text(String(value.prefix(30)) + "...")
                                    .font(PryTheme.Typography.body)
                                    .multilineTextAlignment(.trailing)
                                CopyButtonView(valueToCopy: value)
                            }
                        } else {
                            DetailRowView(label: key, value: value)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Body

    @ViewBuilder
    private var bodySection: some View {
        if let body = entry.requestBody, !body.isEmpty, !body.hasPrefix("[Binary data:") {
            DetailSectionView(title: "Body", collapsible: true, startCollapsed: true) {
                CodeBlockView(text: body, language: .json)
            }
        }
    }

    // MARK: - Query Params

    @ViewBuilder
    private var queryParamsSection: some View {
        if let queryItems = URLComponents(string: entry.requestURL)?.queryItems, !queryItems.isEmpty {
            DetailSectionView(title: "Query Parameters", collapsible: true) {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                    ForEach(queryItems, id: \.name) { param in
                        DetailRowView(label: param.name, value: param.value ?? "nil")
                    }
                }
            }
        }
    }
}
