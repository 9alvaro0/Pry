import SwiftUI
import UIKit

@_spi(PryPro) public struct NetworkRequestDetailView: View {
    @_spi(PryPro) public let entry: NetworkEntry

    @Environment(\.pryStore) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showCopied = false

    @_spi(PryPro) public init(entry: NetworkEntry) {
        self.entry = entry
    }

    @_spi(PryPro) public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                summaryHeader
                Divider().overlay(PryTheme.Colors.border)

                graphQLSection
                timingSection
                redirectChainSection
                jwtSection

                requestHeadersSection
                requestBodySection
                queryParamsSection

                if entry.responseStatusCode != nil || entry.responseError != nil {
                    HStack(spacing: PryTheme.Spacing.sm) {
                        VStack { Divider().overlay(PryTheme.Colors.border) }
                        Text("RESPONSE")
                            .font(PryTheme.Typography.detail)
                            .fontWeight(.semibold)
                            .foregroundStyle(PryTheme.Colors.textTertiary)
                            .fixedSize()
                        VStack { Divider().overlay(PryTheme.Colors.border) }
                    }
                    .padding(.vertical, PryTheme.Spacing.sm)
                }

                responseHeadersSection
                responseBodySection
                errorSection
            }
            .padding(.horizontal, PryTheme.Spacing.lg)
        }
        .pryBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .overlay(alignment: .top) {
            if showCopied {
                copiedToast
            }
        }
        .animation(.easeInOut(duration: PryTheme.Animation.standard), value: showCopied)
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.md) {
            HStack(spacing: PryTheme.Spacing.sm) {
                if let statusCode = entry.responseStatusCode {
                    HStack(spacing: PryTheme.Spacing.xs) {
                        Text("\(statusCode)")
                            .pryStatusBadge(statusCode)

                        let desc = HTTPStatus.description(for: statusCode)
                        if !desc.isEmpty {
                            Text(desc)
                                .font(PryTheme.Typography.body)
                                .foregroundStyle(PryTheme.Colors.textSecondary)
                        }
                    }
                } else if entry.responseError != nil {
                    statusLabel("ERROR", color: PryTheme.Colors.error)
                } else {
                    statusLabel("PENDING", color: PryTheme.Colors.pending)
                }

                Spacer()

                if let duration = entry.duration {
                    Text(duration.formattedDuration)
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.textSecondary)
                }

                if let size = entry.responseSize, size > 0 {
                    Text(size.formatBytes())
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.textSecondary)
                }

                if entry.redirectCount > 0 {
                    Text("\(entry.redirectCount) redirect\(entry.redirectCount == 1 ? "" : "s")")
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.warning)
                }
            }

            Text(entry.requestURL)
                .font(PryTheme.Typography.codeSmall)
                .foregroundStyle(PryTheme.Colors.textSecondary)
                .textSelection(.enabled)
                .lineLimit(3)

            Text(entry.timestamp.formatFullTimestamp())
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
        .padding(.vertical, PryTheme.Spacing.lg)
    }

    // MARK: - GraphQL

    @ViewBuilder
    private var graphQLSection: some View {
        if let gql = entry.graphQLInfo {
            DetailSectionView(title: "GraphQL", collapsible: false) {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.md) {
                    HStack(spacing: PryTheme.Spacing.sm) {
                        Text(gql.operationType.rawValue)
                            .font(PryTheme.Typography.code)
                            .fontWeight(.bold)
                            .foregroundStyle(gql.operationType.color)
                            .padding(.horizontal, PryTheme.Spacing.sm)
                            .padding(.vertical, PryTheme.Spacing.xxs)
                            .background(gql.operationType.color.opacity(PryTheme.Opacity.badge))
                            .clipShape(.capsule)

                        if let name = gql.operationName {
                            Text(name)
                                .font(PryTheme.Typography.code)
                                .fontWeight(.semibold)
                                .foregroundStyle(PryTheme.Colors.textPrimary)
                        } else {
                            Text("Anonymous")
                                .font(PryTheme.Typography.code)
                                .foregroundStyle(PryTheme.Colors.textTertiary)
                                .italic()
                        }
                    }

                    if gql.hasErrors {
                        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                            ForEach(Array(gql.errors.enumerated()), id: \.offset) { _, error in
                                HStack(alignment: .top, spacing: PryTheme.Spacing.xs) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(PryTheme.Typography.sectionLabel)
                                        .foregroundStyle(PryTheme.Colors.error)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(error.message)
                                            .font(PryTheme.Typography.code)
                                            .foregroundStyle(PryTheme.Colors.error)
                                        if let path = error.path {
                                            Text(path)
                                                .font(PryTheme.Typography.detail)
                                                .foregroundStyle(PryTheme.Colors.textTertiary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(PryTheme.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PryTheme.Colors.error.opacity(PryTheme.Opacity.faint))
                        .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))
                    }

                    CodeBlockView(text: gql.query, language: .text)

                    if let variables = gql.variables {
                        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                            Text("VARIABLES")
                                .font(PryTheme.Typography.sectionLabel)
                                .tracking(PryTheme.Text.tracking)
                                .foregroundStyle(PryTheme.Colors.textTertiary)

                            CodeBlockView(text: variables, language: .json)
                        }
                    }
                }
            }
        }
    }

    // MARK: - JWT Token

    @ViewBuilder
    private var jwtSection: some View {
        let token = entry.authToken
            ?? entry.requestHeaders["Authorization"]
        if let token, JWTDecoder.decode(token) != nil {
            DetailSectionView(title: "JWT Token", collapsible: true) {
                JWTDetailView(token: token)
            }
        }
    }

    // MARK: - Timing Breakdown

    @ViewBuilder
    private var timingSection: some View {
        if let metrics = entry.metrics {
            DetailSectionView(title: "Timing Breakdown", collapsible: true) {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                    timingRow("DNS Lookup", value: metrics.dnsLookup)
                    timingRow("TCP Connect", value: metrics.tcpConnect)
                    timingRow("TLS Handshake", value: metrics.tlsHandshake)
                    timingRow("Request Sent", value: metrics.requestSent)
                    timingRow("Waiting (TTFB)", value: metrics.waitingForResponse)
                    timingRow("Response Received", value: metrics.responseReceived)
                }
            }
        }
    }

    private func timingRow(_ label: String, value: TimeInterval?) -> some View {
        HStack {
            Text(label)
                .font(PryTheme.Typography.body)
                .foregroundStyle(PryTheme.Colors.textSecondary)
            Spacer()
            Text(value.map { String(format: "%.1fms", $0 * 1000) } ?? "-")
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
        }
    }

    // MARK: - Redirect Chain

    @ViewBuilder
    private var redirectChainSection: some View {
        if !entry.redirects.isEmpty {
            DetailSectionView(title: "Redirect Chain", collapsible: true) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entry.redirects.enumerated()), id: \.element.id) { index, hop in
                        redirectHopRow(statusCode: hop.statusCode, url: hop.fromURL)
                        redirectConnector
                        if index == entry.redirects.count - 1 {
                            redirectHopRow(
                                statusCode: entry.responseStatusCode ?? 0,
                                url: hop.toURL,
                                isFinal: true
                            )
                        }
                    }
                }
            }
        }
    }

    private func redirectHopRow(statusCode: Int, url: String, isFinal: Bool = false) -> some View {
        HStack(alignment: .center, spacing: PryTheme.Spacing.sm) {
            Text("\(statusCode)")
                .pryStatusBadge(statusCode)

            Text(url)
                .font(PryTheme.Typography.codeSmall)
                .foregroundStyle(isFinal ? PryTheme.Colors.textPrimary : PryTheme.Colors.textSecondary)
                .lineLimit(2)
                .truncationMode(.middle)
                .textSelection(.enabled)

            Spacer(minLength: 0)

            CopyButtonView(valueToCopy: url)
        }
        .padding(.vertical, PryTheme.Spacing.xs)
    }

    private var redirectConnector: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(PryTheme.Colors.border)
                .frame(width: 1, height: 14)
                .padding(.leading, 18)
            Spacer()
        }
    }

    // MARK: - Request Headers

    @ViewBuilder
    private var requestHeadersSection: some View {
        let headers = displayHeaders
        if !headers.isEmpty {
            DetailSectionView(title: "Request Headers", collapsible: true, startCollapsed: true) {
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

    // MARK: - Request Body

    @ViewBuilder
    private var requestBodySection: some View {
        if let body = entry.requestBody, !body.isEmpty, !body.hasPrefix("[Binary data:") {
            DetailSectionView(title: "Request Body", collapsible: true) {
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

    // MARK: - Response Headers

    @ViewBuilder
    private var responseHeadersSection: some View {
        if let responseHeaders = entry.responseHeaders, !responseHeaders.isEmpty {
            DetailSectionView(title: "Response Headers", collapsible: true, startCollapsed: true) {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                    ForEach(Array(responseHeaders.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        DetailRowView(label: key, value: value)
                    }
                }
            }
        }
    }

    // MARK: - Response Body

    @ViewBuilder
    private var responseBodySection: some View {
        if let body = entry.responseBody, !body.isEmpty, !body.hasPrefix("[Binary data:"), entry.displayError == nil {
            DetailSectionView(title: "Response Body", collapsible: true) {
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

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("\(entry.requestMethod) \(entry.displayPath)")
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    store.togglePin(entry.id)
                } label: {
                    Label(
                        store.isPinned(entry.id) ? "Unpin" : "Pin",
                        systemImage: store.isPinned(entry.id) ? "pin.slash" : "pin"
                    )
                }

                ShareLink(item: generateShareText()) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button { copyToClipboard(generateCurlCommand()) } label: {
                    Label("Copy cURL", systemImage: "terminal.fill")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(PryTheme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Toasts

    private var copiedToast: some View {
        toastView(icon: "checkmark", text: "Copied", color: PryTheme.Colors.success)
    }

    private func toastView(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: PryTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(PryTheme.Typography.detail)
            Text(text)
                .font(PryTheme.Typography.detail)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, PryTheme.Spacing.md)
        .padding(.vertical, PryTheme.Spacing.sm)
        .background(color)
        .clipShape(.capsule)
        .transition(.move(edge: .top).combined(with: .opacity))
        .padding(.top, PryTheme.Spacing.sm)
    }

    // MARK: - Actions

    private func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
        showToast($showCopied, duration: PryTheme.Animation.toastDismiss)
    }

    private func generateShareText() -> String {
        var lines: [String] = []

        let path = entry.requestURL.extractPath()
        var summary = "\(entry.requestMethod) \(path)"
        if let statusCode = entry.responseStatusCode {
            let desc = HTTPStatus.description(for: statusCode)
            summary += " \u{2192} \(statusCode)"
            if !desc.isEmpty { summary += " \(desc)" }
        } else if entry.responseError != nil {
            summary += " \u{2192} ERROR"
        }
        if let duration = entry.duration {
            summary += " (\(duration.formattedDuration))"
        }
        lines.append(summary)
        lines.append(entry.requestURL)

        let reqHeaders = displayHeaders
        if !reqHeaders.isEmpty {
            lines.append("")
            lines.append("\u{2500}\u{2500} Request Headers \u{2500}\u{2500}")
            for (key, value) in reqHeaders.sorted(by: { $0.key < $1.key }) {
                lines.append("\(key): \(value)")
            }
        }

        if let body = entry.requestBody, !body.isEmpty {
            lines.append("")
            lines.append("\u{2500}\u{2500} Request Body \u{2500}\u{2500}")
            lines.append(body)
        }

        if let resHeaders = entry.responseHeaders, !resHeaders.isEmpty {
            lines.append("")
            lines.append("\u{2500}\u{2500} Response Headers \u{2500}\u{2500}")
            for (key, value) in resHeaders.sorted(by: { $0.key < $1.key }) {
                lines.append("\(key): \(value)")
            }
        }

        if let body = entry.responseBody, !body.isEmpty {
            lines.append("")
            lines.append("\u{2500}\u{2500} Response Body \u{2500}\u{2500}")
            lines.append(body)
        }

        if let error = entry.responseError, !error.isEmpty {
            lines.append("")
            lines.append("\u{2500}\u{2500} Error \u{2500}\u{2500}")
            lines.append(error)
        }

        return lines.joined(separator: "\n")
    }

    private func generateCurlCommand() -> String {
        var components: [String] = ["curl", "--location", "--silent", "--show-error"]

        if entry.requestMethod != "GET" {
            components.append("--request \(entry.requestMethod)")
        }

        let realHeaders = curlHeaders

        if let token = entry.authToken, !token.isEmpty {
            let authToken = token.hasPrefix("Bearer ") ? token : "Bearer \(token)"
            components.append("--header 'Authorization: \(escapeCurl(authToken))'")
        } else if let authHeader = realHeaders["Authorization"] {
            components.append("--header 'Authorization: \(escapeCurl(authHeader))'")
        }

        for (key, value) in realHeaders.sorted(by: { $0.key < $1.key }) where key != "Authorization" {
            components.append("--header '\(escapeCurl(key)): \(escapeCurl(value))'")
        }

        if entry.requestBody != nil && !realHeaders.keys.contains("Content-Type") {
            components.append("--header 'Content-Type: application/json'")
        }

        if let body = entry.requestBody, !body.isEmpty {
            components.append("--data '\(escapeCurl(body))'")
        }

        components.append("'\(escapeCurl(entry.requestURL))'")

        return components.joined(separator: " \\\n  ")
    }

    private func statusLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(PryTheme.Typography.codeSmall)
            .fontWeight(.medium)
            .padding(.horizontal, PryTheme.Spacing.pip)
            .padding(.vertical, PryTheme.Spacing.xxs)
            .background(color.opacity(PryTheme.Opacity.badge))
            .foregroundStyle(color)
            .clipShape(.capsule)
    }

    private func showToast(_ flag: Binding<Bool>, duration: Duration = PryTheme.Animation.toastLong) {
        flag.wrappedValue = true
        Task {
            try? await Task.sleep(for: duration)
            flag.wrappedValue = false
        }
    }

    private func escapeCurl(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "'\"'\"'")
    }

    private static let internalHeaders: Set<String> = ["Content-Length", "Accept-Encoding", "X-Pry-Replay"]
    private static let curlExtraSkip: Set<String> = ["Host", "User-Agent"]

    private var displayHeaders: [String: String] {
        entry.requestHeaders.filter { key, _ in
            !key.hasPrefix("X-Debug-") && !Self.internalHeaders.contains(key)
        }
    }

    private var curlHeaders: [String: String] {
        entry.requestHeaders.filter { key, _ in
            !key.hasPrefix("X-Debug-") && !Self.internalHeaders.contains(key) && !Self.curlExtraSkip.contains(key)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Detail - Success POST") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockSuccess)
    }
}

#Preview("Detail - 404 Error") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockError)
    }
}

#Preview("Detail - 500 Error") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockServerError)
    }
}

#Preview("Detail - Pending") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockPending)
    }
}

#Preview("Detail - Redirect + Timing") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockRedirect)
    }
}
#endif
