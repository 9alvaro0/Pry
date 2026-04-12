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
            HeadersView(headers: headers, title: "Headers")
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
