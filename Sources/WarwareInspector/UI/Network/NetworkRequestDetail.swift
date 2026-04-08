import SwiftUI

struct NetworkRequestDetailView: View {
    let entry: NetworkEntry

    @Environment(\.inspectorStore) private var store
    @State private var showCopied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                summaryHeader
                Divider().overlay(InspectorTheme.Colors.border)

                timingSection

                // Auth / JWT
                jwtSection

                // Request
                requestHeadersSection
                requestBodySection
                queryParamsSection

                // Divider between Request and Response
                if entry.responseStatusCode != nil || entry.responseError != nil {
                    HStack(spacing: InspectorTheme.Spacing.sm) {
                        VStack { Divider().overlay(InspectorTheme.Colors.border) }
                        Text("RESPONSE")
                            .font(InspectorTheme.Typography.detail)
                            .fontWeight(.semibold)
                            .foregroundStyle(InspectorTheme.Colors.textTertiary)
                            .fixedSize()
                        VStack { Divider().overlay(InspectorTheme.Colors.border) }
                    }
                    .padding(.vertical, InspectorTheme.Spacing.sm)
                }

                // Response
                responseHeadersSection
                responseBodySection
                errorSection
            }
            .padding(.horizontal, InspectorTheme.Spacing.lg)
        }
        .inspectorBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .overlay(alignment: .top) {
            if showCopied {
                copiedToast
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCopied)
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.md) {
            // Status + Duration + Size
            HStack(spacing: InspectorTheme.Spacing.sm) {
                if let statusCode = entry.responseStatusCode {
                    HStack(spacing: InspectorTheme.Spacing.xs) {
                        Text("\(statusCode)")
                            .inspectorStatusBadge(statusCode)

                        let desc = HTTPStatus.description(for: statusCode)
                        if !desc.isEmpty {
                            Text(desc)
                                .font(InspectorTheme.Typography.body)
                                .foregroundStyle(InspectorTheme.Colors.textSecondary)
                        }
                    }
                } else if entry.responseError != nil {
                    Text("ERROR")
                        .font(InspectorTheme.Typography.codeSmall)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, InspectorTheme.Spacing.xxs)
                        .background(InspectorTheme.Colors.error.opacity(0.15))
                        .foregroundStyle(InspectorTheme.Colors.error)
                        .clipShape(.capsule)
                } else {
                    Text("PENDING")
                        .font(InspectorTheme.Typography.codeSmall)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, InspectorTheme.Spacing.xxs)
                        .background(InspectorTheme.Colors.pending.opacity(0.15))
                        .foregroundStyle(InspectorTheme.Colors.pending)
                        .clipShape(.capsule)
                }

                Spacer()

                if let duration = entry.duration {
                    Text(Optional(duration).formattedDuration)
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.textSecondary)
                }

                if let size = entry.responseSize, size > 0 {
                    Text(size.formatBytes())
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.textSecondary)
                }

                if entry.redirectCount > 0 {
                    Text("\(entry.redirectCount) redirect\(entry.redirectCount == 1 ? "" : "s")")
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.warning)
                }
            }

            // Full URL (copyable)
            Text(entry.requestURL)
                .font(InspectorTheme.Typography.codeSmall)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)
                .textSelection(.enabled)
                .lineLimit(3)

            // Timestamp
            Text(entry.timestamp.formatFullTimestamp())
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
        .padding(.vertical, InspectorTheme.Spacing.lg)
    }

    // MARK: - JWT Token

    @ViewBuilder
    private var jwtSection: some View {
        // Check Authorization header or auth token for JWT
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
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
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
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)
            Spacer()
            Text(value.map { String(format: "%.1fms", $0 * 1000) } ?? "-")
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
        }
    }

    // MARK: - Request Headers

    @ViewBuilder
    private var requestHeadersSection: some View {
        let headers = entry.requestHeaders.filter { key, _ in
            !key.hasPrefix("X-Debug-") &&
            !["Content-Length", "Accept-Encoding"].contains(key)
        }
        if !headers.isEmpty {
            DetailSectionView(title: "Request Headers", collapsible: true, startCollapsed: true) {
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                    ForEach(Array(headers.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        DetailRowView(label: key, value: value)
                    }
                }
            }
        }
    }

    // MARK: - Request Body

    @ViewBuilder
    private var requestBodySection: some View {
        if let body = entry.requestBody, !body.isEmpty {
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
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
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
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
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
        if let body = entry.responseBody, !body.isEmpty, entry.displayError == nil {
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
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
                    Text(error)
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.error)
                        .padding(InspectorTheme.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(InspectorTheme.Colors.error.opacity(0.1))
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))

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
            Text("\(entry.requestMethod) \(entry.requestURL.extractPath())")
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                store.togglePin(entry.id)
            } label: {
                Image(systemName: store.isPinned(entry.id) ? "pin.fill" : "pin")
                    .font(InspectorTheme.Typography.body)
                    .foregroundStyle(store.isPinned(entry.id) ? InspectorTheme.Colors.warning : InspectorTheme.Colors.textSecondary)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            ShareLink(item: generateShareText()) {
                Image(systemName: "square.and.arrow.up")
                    .font(InspectorTheme.Typography.body)
                    .foregroundStyle(InspectorTheme.Colors.textSecondary)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button { copyToClipboard(generateCurlCommand()) } label: {
                    Label("Copy as cURL", systemImage: "terminal.fill")
                }
                Button { copyToClipboard(entry.requestURL) } label: {
                    Label("Copy URL", systemImage: "link")
                }
                if let body = entry.responseBody, !body.isEmpty {
                    Button { copyToClipboard(body) } label: {
                        Label("Copy Response", systemImage: "doc.on.doc")
                    }
                }
            } label: {
                Image(systemName: "square.on.square")
                    .font(InspectorTheme.Typography.body)
                    .foregroundStyle(InspectorTheme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Copied Toast

    private var copiedToast: some View {
        Text("Copied!")
            .font(InspectorTheme.Typography.detail)
            .fontWeight(.semibold)
            .foregroundStyle(InspectorTheme.Colors.success)
            .padding(.horizontal, InspectorTheme.Spacing.md)
            .padding(.vertical, InspectorTheme.Spacing.xs)
            .background(InspectorTheme.Colors.success.opacity(0.15))
            .clipShape(.capsule)
            .transition(.move(edge: .top).combined(with: .opacity))
            .padding(.top, InspectorTheme.Spacing.sm)
    }

    // MARK: - Actions

    private func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
        showCopied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            showCopied = false
        }
    }

    private func generateShareText() -> String {
        var lines: [String] = []

        // Summary line: METHOD /path -> STATUS (duration)
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
            summary += " (\(Optional(duration).formattedDuration))"
        }
        lines.append(summary)
        lines.append(entry.requestURL)

        // Request headers
        let reqHeaders = entry.requestHeaders.filter { key, _ in
            !key.hasPrefix("X-Debug-") &&
            !["Content-Length", "Accept-Encoding"].contains(key)
        }
        if !reqHeaders.isEmpty {
            lines.append("")
            lines.append("\u{2500}\u{2500} Request Headers \u{2500}\u{2500}")
            for (key, value) in reqHeaders.sorted(by: { $0.key < $1.key }) {
                lines.append("\(key): \(value)")
            }
        }

        // Request body
        if let body = entry.requestBody, !body.isEmpty {
            lines.append("")
            lines.append("\u{2500}\u{2500} Request Body \u{2500}\u{2500}")
            lines.append(body)
        }

        // Response headers
        if let resHeaders = entry.responseHeaders, !resHeaders.isEmpty {
            lines.append("")
            lines.append("\u{2500}\u{2500} Response Headers \u{2500}\u{2500}")
            for (key, value) in resHeaders.sorted(by: { $0.key < $1.key }) {
                lines.append("\(key): \(value)")
            }
        }

        // Response body
        if let body = entry.responseBody, !body.isEmpty {
            lines.append("")
            lines.append("\u{2500}\u{2500} Response Body \u{2500}\u{2500}")
            lines.append(body)
        }

        // Error
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

        let realHeaders = entry.requestHeaders.filter { key, _ in
            !key.hasPrefix("X-Debug-") &&
            !["Content-Length", "Host", "User-Agent", "Accept-Encoding"].contains(key)
        }

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

    private func escapeCurl(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "'\"'\"'")
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

#Preview("Detail - PATCH") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockPatch)
    }
}

#Preview("Detail - Form POST") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockFormPost)
    }
}

#Preview("Detail - Redirect + Timing") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockRedirect)
    }
}

#Preview("Detail - Timing Breakdown") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockSuccess)
    }
}
#endif
