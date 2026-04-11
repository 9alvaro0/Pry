import SwiftUI

/// Response tab: headers, body, error.
struct NetworkDetailResponse: View {
    let entry: NetworkEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headersSection
            bodySection
            errorSection
        }
    }

    // MARK: - Headers

    @ViewBuilder
    private var headersSection: some View {
        if let responseHeaders = entry.responseHeaders, !responseHeaders.isEmpty {
            DetailSectionView(title: "Headers", collapsible: true) {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                    ForEach(Array(responseHeaders.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        DetailRowView(label: key, value: value)
                    }
                }
            }
        }
    }

    // MARK: - Body

    @ViewBuilder
    private var bodySection: some View {
        if let body = entry.responseBody, !body.isEmpty, !body.hasPrefix("[Binary data:"), entry.displayError == nil {
            DetailSectionView(title: "Body", collapsible: true) {
                CodeBlockView(text: body, language: .json)
            }
        }
    }

    // MARK: - Error

    @ViewBuilder
    private var errorSection: some View {
        if let error = entry.displayError {
            DetailSectionView(title: "Error") {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                    Text(error)
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.error)
                        .padding(PryTheme.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PryTheme.Colors.error.opacity(PryTheme.Opacity.border))
                        .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))

                    if entry.hasErrorResponseBody, let responseBody = entry.responseBody {
                        CodeBlockView(text: responseBody, language: .json)
                    }
                }
            }
        }
    }
}
