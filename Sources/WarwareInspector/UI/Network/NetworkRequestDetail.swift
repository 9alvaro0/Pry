import SwiftUI

struct NetworkRequestDetailView: View {
    let entry: NetworkEntry

    @Environment(\.inspectorStore) private var store
    @Environment(\.inspectorReadOnly) private var isReadOnly
    @Environment(\.dismiss) private var dismiss
    @State private var showCopied = false
    @State private var showMockEditor = false
    @State private var showMockSaved = false
    @State private var showMockRemoved = false
    @State private var hadMockBeforeEdit = false
    @State private var showReplayed = false
    @State private var isReplaying = false
    @State private var showDiffPicker = false
    @State private var diffTarget: NetworkEntry?
    @State private var showBreakpointCreator = false
    @State private var showBreakpointSaved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Replay banner
                if entry.isReplay {
                    HStack(spacing: InspectorTheme.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                            .font(InspectorTheme.Typography.body)
                        Text("Replayed Request")
                            .font(InspectorTheme.Typography.body)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundStyle(InspectorTheme.Colors.accent)
                    .padding(.horizontal, InspectorTheme.Spacing.lg)
                    .padding(.vertical, InspectorTheme.Spacing.sm)
                    .background(InspectorTheme.Colors.accent.opacity(InspectorTheme.Opacity.tint))
                }

                // Mocked banner (tappable → opens editor)
                if entry.isMocked {
                    Button { hadMockBeforeEdit = hasMockActive; showMockEditor = true } label: {
                        HStack(spacing: InspectorTheme.Spacing.sm) {
                            Image(systemName: "theatermasks.fill")
                                .font(InspectorTheme.Typography.body)
                            Text("Mocked Response")
                                .font(InspectorTheme.Typography.body)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("Edit")
                                .font(InspectorTheme.Typography.detail)
                            Image(systemName: "chevron.right")
                                .font(InspectorTheme.Typography.detail)
                        }
                        .foregroundStyle(InspectorTheme.Colors.syntaxBool)
                        .padding(.horizontal, InspectorTheme.Spacing.lg)
                        .padding(.vertical, InspectorTheme.Spacing.sm)
                        .background(InspectorTheme.Colors.syntaxBool.opacity(InspectorTheme.Opacity.tint))
                    }
                }

                summaryHeader
                Divider().overlay(InspectorTheme.Colors.border)

                // GraphQL
                graphQLSection

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
        .sheet(isPresented: $showMockEditor, onDismiss: {
            let hasMockNow = store.mockRules.contains {
                $0.urlPattern == entry.requestURL.extractPath() && $0.method == entry.requestMethod && $0.isEnabled
            }
            if hasMockNow && !hadMockBeforeEdit {
                showToast($showMockSaved)
            } else if !hasMockNow && hadMockBeforeEdit {
                showToast($showMockRemoved)
            }
        }) {
            ResponseOverrideView(entry: entry)
                .environment(\.inspectorStore, store)
        }
        .sheet(isPresented: $showDiffPicker) {
            DiffPickerSheet(entries: store.networkEntries, currentEntry: entry) { selected in
                diffTarget = selected
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(InspectorTheme.Colors.background)
        }
        .sheet(item: $diffTarget) { target in
            RequestDiffView(left: entry, right: target)
        }
        .sheet(isPresented: $showBreakpointCreator, onDismiss: {
            if hasBreakpointActive && !showBreakpointSaved {
                showToast($showBreakpointSaved)
            }
        }) {
            BreakpointRuleEditor(store: store, prefillEntry: entry)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(InspectorTheme.Colors.background)
        }
        .overlay(alignment: .top) {
            if showCopied {
                copiedToast
            }
            if showMockSaved {
                mockSavedToast
            }
            if showMockRemoved {
                mockRemovedToast
            }
            if showReplayed {
                replayedToast
            }
            if showBreakpointSaved {
                breakpointSavedToast
            }
        }
        .animation(.easeInOut(duration: InspectorTheme.Animation.standard), value: showCopied)
        .animation(.easeInOut(duration: InspectorTheme.Animation.standard), value: showMockSaved)
        .animation(.easeInOut(duration: InspectorTheme.Animation.standard), value: showMockRemoved)
        .animation(.easeInOut(duration: InspectorTheme.Animation.standard), value: showBreakpointSaved)
        .animation(.easeInOut(duration: InspectorTheme.Animation.standard), value: showReplayed)
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
                        .padding(.horizontal, InspectorTheme.Spacing.pip)
                        .padding(.vertical, InspectorTheme.Spacing.xxs)
                        .background(InspectorTheme.Colors.error.opacity(InspectorTheme.Opacity.badge))
                        .foregroundStyle(InspectorTheme.Colors.error)
                        .clipShape(.capsule)
                } else {
                    Text("PENDING")
                        .font(InspectorTheme.Typography.codeSmall)
                        .fontWeight(.medium)
                        .padding(.horizontal, InspectorTheme.Spacing.pip)
                        .padding(.vertical, InspectorTheme.Spacing.xxs)
                        .background(InspectorTheme.Colors.pending.opacity(InspectorTheme.Opacity.badge))
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

    // MARK: - GraphQL

    @ViewBuilder
    private var graphQLSection: some View {
        if let gql = entry.graphQLInfo {
            DetailSectionView(title: "GraphQL", collapsible: false) {
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.md) {
                    // Operation info
                    HStack(spacing: InspectorTheme.Spacing.sm) {
                        Text(gql.operationType.rawValue)
                            .font(InspectorTheme.Typography.code)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                gql.operationType == .mutation
                                    ? InspectorTheme.Colors.warning
                                    : InspectorTheme.Colors.syntaxString
                            )
                            .padding(.horizontal, InspectorTheme.Spacing.sm)
                            .padding(.vertical, InspectorTheme.Spacing.xxs)
                            .background(
                                (gql.operationType == .mutation
                                    ? InspectorTheme.Colors.warning
                                    : InspectorTheme.Colors.syntaxString
                                ).opacity(InspectorTheme.Opacity.badge)
                            )
                            .clipShape(.capsule)

                        if let name = gql.operationName {
                            Text(name)
                                .font(InspectorTheme.Typography.code)
                                .fontWeight(.semibold)
                                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                        } else {
                            Text("Anonymous")
                                .font(InspectorTheme.Typography.code)
                                .foregroundStyle(InspectorTheme.Colors.textTertiary)
                                .italic()
                        }
                    }

                    // GraphQL errors
                    if gql.hasErrors {
                        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                            ForEach(Array(gql.errors.enumerated()), id: \.offset) { _, error in
                                HStack(alignment: .top, spacing: InspectorTheme.Spacing.xs) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(InspectorTheme.Typography.sectionLabel)
                                        .foregroundStyle(InspectorTheme.Colors.error)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(error.message)
                                            .font(InspectorTheme.Typography.code)
                                            .foregroundStyle(InspectorTheme.Colors.error)
                                        if let path = error.path {
                                            Text(path)
                                                .font(InspectorTheme.Typography.detail)
                                                .foregroundStyle(InspectorTheme.Colors.textTertiary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(InspectorTheme.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(InspectorTheme.Colors.error.opacity(InspectorTheme.Opacity.faint))
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))
                    }

                    // Query
                    CodeBlockView(text: gql.query, language: .text)

                    // Variables
                    if let variables = gql.variables {
                        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                            Text("VARIABLES")
                                .font(InspectorTheme.Typography.sectionLabel)
                                .tracking(InspectorTheme.Text.tracking)
                                .foregroundStyle(InspectorTheme.Colors.textTertiary)

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
        let headers = displayHeaders
        if !headers.isEmpty {
            DetailSectionView(title: "Request Headers", collapsible: true, startCollapsed: true) {
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                    ForEach(Array(headers.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        if key == "Authorization", value.count > 50 {
                            HStack(alignment: .top) {
                                Text(key)
                                    .font(InspectorTheme.Typography.body)
                                    .foregroundStyle(InspectorTheme.Colors.textSecondary)
                                Spacer(minLength: InspectorTheme.Spacing.sm)
                                Text(String(value.prefix(30)) + "...")
                                    .font(InspectorTheme.Typography.body)
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
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
                    Text(error)
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.error)
                        .padding(InspectorTheme.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(InspectorTheme.Colors.error.opacity(InspectorTheme.Opacity.border))
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))

                    if entry.hasErrorResponseBody, let responseBody = entry.responseBody {
                        CodeBlockView(text: responseBody, language: .json)
                    }
                }
            }
        }
    }

    private var hasMockActive: Bool {
        entry.isMocked ||
        store.mockRules.contains {
            $0.urlPattern == entry.requestURL.extractPath() &&
            $0.method == entry.requestMethod &&
            $0.isEnabled
        }
    }

    private var hasActiveRules: Bool {
        hasMockActive || hasBreakpointActive
    }

    private var hasBreakpointActive: Bool {
        store.breakpointRules.contains {
            $0.isEnabled &&
            (entry.requestURL.localizedCaseInsensitiveContains($0.urlPattern))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("\(entry.requestMethod) \(entry.displayPath)")
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                // Intercept section (mock + breakpoint)
                if !isReadOnly {
                    Section("Intercept") {
                        Button {
                            hadMockBeforeEdit = hasMockActive
                            showMockEditor = true
                        } label: {
                            Label(
                                hasMockActive ? "Edit Mock" : "Mock Response",
                                systemImage: hasMockActive ? "theatermasks.fill" : "theatermasks"
                            )
                        }

                        Button {
                            showBreakpointCreator = true
                        } label: {
                            Label(
                                hasBreakpointActive ? "Breakpoint Active" : "Add Breakpoint",
                                systemImage: hasBreakpointActive ? "pause.circle.fill" : "pause.circle"
                            )
                        }
                    }
                }

                // Actions section
                if !isReadOnly {
                    Section {
                        Button {
                            replayRequest()
                        } label: {
                            Label("Replay", systemImage: "arrow.clockwise")
                        }
                        .disabled(isReplaying)

                        Button {
                            store.togglePin(entry.id)
                        } label: {
                            Label(
                                store.isPinned(entry.id) ? "Unpin" : "Pin",
                                systemImage: store.isPinned(entry.id) ? "pin.slash" : "pin"
                            )
                        }
                    }
                }

                // Share section
                Section {
                    Button {
                        showDiffPicker = true
                    } label: {
                        Label("Compare", systemImage: "arrow.left.arrow.right")
                    }

                    ShareLink(item: generateShareText()) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Button { copyToClipboard(generateCurlCommand()) } label: {
                        Label("Copy cURL", systemImage: "terminal.fill")
                    }
                }
            } label: {
                Image(systemName: hasActiveRules ? "ellipsis.circle.fill" : "ellipsis.circle")
                    .font(InspectorTheme.Typography.body)
                    .foregroundStyle(hasActiveRules ? InspectorTheme.Colors.warning : InspectorTheme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Toasts

    private var copiedToast: some View {
        toastView(icon: "checkmark", text: "Copied", color: InspectorTheme.Colors.success)
    }

    private var mockSavedToast: some View {
        toastView(icon: "theatermasks.fill", text: "Mock saved", color: InspectorTheme.Colors.syntaxBool)
    }

    private var mockRemovedToast: some View {
        toastView(icon: "theatermasks", text: "Mock removed", color: InspectorTheme.Colors.error)
    }

    private var replayedToast: some View {
        toastView(icon: "arrow.clockwise", text: "Request replayed", color: InspectorTheme.Colors.accent)
    }

    private var breakpointSavedToast: some View {
        toastView(icon: "pause.circle.fill", text: "Breakpoint set", color: InspectorTheme.Colors.warning)
    }

    private func toastView(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: InspectorTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(InspectorTheme.Typography.detail)
            Text(text)
                .font(InspectorTheme.Typography.detail)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, InspectorTheme.Spacing.md)
        .padding(.vertical, InspectorTheme.Spacing.sm)
        .background(color)
        .clipShape(.capsule)
        .transition(.move(edge: .top).combined(with: .opacity))
        .padding(.top, InspectorTheme.Spacing.sm)
    }

    // MARK: - Actions

    private func replayRequest() {
        guard let url = URL(string: entry.requestURL) else { return }
        isReplaying = true

        var request = URLRequest(url: url)
        request.httpMethod = entry.requestMethod

        // Restore headers (skip internal/transport headers)
        let skipHeaders: Set<String> = ["Host", "Content-Length", "Accept-Encoding"]
        for (key, value) in entry.requestHeaders where !skipHeaders.contains(key) {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Tag as replay so the logger can mark the new entry
        request.setValue("true", forHTTPHeaderField: "X-WarwareInspector-Replay")

        // Restore body (skip special encoded bodies like [IMAGE:...] or [Binary data:...])
        if let body = entry.requestBody, !body.isEmpty,
           !body.hasPrefix("[IMAGE:"), !body.hasPrefix("[Binary data:") {
            request.httpBody = body.data(using: .utf8)
        }

        // Fire through URLSession.shared so the interceptor captures it as a new entry
        Task {
            _ = try? await URLSession.shared.data(for: request)
            await MainActor.run {
                isReplaying = false
                showReplayed = true
            }
            try? await Task.sleep(for: InspectorTheme.Animation.replayDismiss)
            await MainActor.run {
                showReplayed = false
                dismiss()
            }
        }
    }

    private func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
        showToast($showCopied, duration: InspectorTheme.Animation.toastDismiss)
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
        let reqHeaders = displayHeaders
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

    private func showToast(_ flag: Binding<Bool>, duration: Duration = InspectorTheme.Animation.toastLong) {
        flag.wrappedValue = true
        Task {
            try? await Task.sleep(for: duration)
            flag.wrappedValue = false
        }
    }

    private func escapeCurl(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "'\"'\"'")
    }

    /// Filters out internal/transport headers from request headers.
    private static let internalHeaders: Set<String> = ["Content-Length", "Accept-Encoding", "X-WarwareInspector-Replay"]
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

#Preview("Detail - Replay") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockReplay)
    }
}

#Preview("Detail - GraphQL Query") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockGraphQLQuery)
    }
}

#Preview("Detail - GraphQL Mutation") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockGraphQLMutation)
    }
}

#Preview("Detail - GraphQL Errors") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockGraphQLError)
    }
}
#endif
