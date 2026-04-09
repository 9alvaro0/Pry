import SwiftUI

struct DeeplinkSimulatorView: View {
    @Bindable var store: PryStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    // Mode
    @State private var mode: InputMode = .raw

    // Raw mode
    @State private var urlInput: String = {
        let scheme = Self.defaultScheme()
        return scheme.isEmpty ? "" : "\(scheme)://"
    }()

    // Builder mode
    @State private var scheme: String = Self.defaultScheme()
    @State private var host: String = ""
    @State private var path: String = ""
    @State private var queryParams: [QueryParam] = [QueryParam()]

    // MARK: - Scheme Detection

    /// Reads the app's registered URL schemes from Info.plist and returns the first one.
    private static func defaultScheme() -> String {
        guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] else {
            return ""
        }
        for entry in urlTypes {
            if let schemes = entry["CFBundleURLSchemes"] as? [String], let first = schemes.first {
                return first
            }
        }
        return ""
    }

    // State
    @State private var history: [String] = []
    @State private var validationError: String?
    @State private var sent = false

    private let maxHistory = 5

    private enum InputMode: String, CaseIterable {
        case raw = "URL"
        case builder = "Builder"
    }

    private struct QueryParam: Identifiable {
        let id = UUID()
        var key: String = ""
        var value: String = ""
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.lg) {
                    Picker("", selection: $mode) {
                        ForEach(InputMode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)

                    if mode == .raw {
                        rawContent
                    } else {
                        builderContent
                    }

                    if let error = validationError {
                        Text(error)
                            .font(PryTheme.Typography.detail)
                            .foregroundStyle(PryTheme.Colors.error)
                    }

                    if !history.isEmpty && mode == .raw {
                        historySection
                    }

                    sendButton
                }
                .padding(PryTheme.Spacing.lg)
            }
            .pryBackground()
            .navigationTitle("Simulate Deeplink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(PryTheme.Typography.body)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Raw Mode

    private var rawContent: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
            fieldLabel("URL")

            TextField("myapp://rooms/open?roomId=42", text: $urlInput)
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .padding(PryTheme.Spacing.md)
                .background(PryTheme.Colors.surface)
                .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: PryTheme.Radius.md)
                        .stroke(
                            validationError != nil ? PryTheme.Colors.error : PryTheme.Colors.border,
                            lineWidth: 1
                        )
                )
                .onChange(of: urlInput) { validationError = nil }

            Text("Use any scheme registered by your app, or a Universal Link.")
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
    }

    // MARK: - Builder Mode

    private var builderContent: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.md) {
            builderField("Scheme", placeholder: "myapp", text: $scheme)
            builderField("Host", placeholder: "rooms (optional)", text: $host)
            builderField("Path", placeholder: "/open", text: $path)

            VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                fieldLabel("Query Parameters")

                ForEach($queryParams) { $param in
                    HStack(spacing: PryTheme.Spacing.sm) {
                        TextField("key", text: $param.key)
                            .font(PryTheme.Typography.code)
                            .foregroundStyle(PryTheme.Colors.syntaxKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(PryTheme.Spacing.sm)
                            .background(PryTheme.Colors.surface)
                            .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))

                        Text("=")
                            .font(PryTheme.Typography.code)
                            .foregroundStyle(PryTheme.Colors.textTertiary)

                        TextField("value", text: $param.value)
                            .font(PryTheme.Typography.code)
                            .foregroundStyle(PryTheme.Colors.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(PryTheme.Spacing.sm)
                            .background(PryTheme.Colors.surface)
                            .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))

                        Button {
                            queryParams.removeAll { $0.id == param.id }
                            if queryParams.isEmpty { queryParams.append(QueryParam()) }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(PryTheme.Colors.textTertiary)
                        }
                    }
                }

                Button {
                    queryParams.append(QueryParam())
                } label: {
                    HStack(spacing: PryTheme.Spacing.xs) {
                        Image(systemName: "plus.circle")
                        Text("Add Parameter")
                    }
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.accent)
                }
            }

            // Preview of the built URL
            if !scheme.isEmpty {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                    fieldLabel("Preview")
                    Text(buildURL() ?? "Invalid URL")
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                        .lineLimit(3)
                        .padding(PryTheme.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PryTheme.Colors.surface)
                        .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))
                }
            }
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
            fieldLabel("Recent")

            VStack(spacing: 1) {
                ForEach(history, id: \.self) { url in
                    Button {
                        urlInput = url
                        simulate()
                    } label: {
                        HStack(spacing: PryTheme.Spacing.sm) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(PryTheme.Typography.detail)
                                .foregroundStyle(PryTheme.Colors.textTertiary)

                            Text(url)
                                .font(PryTheme.Typography.codeSmall)
                                .foregroundStyle(PryTheme.Colors.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            Image(systemName: "play.circle")
                                .font(PryTheme.Typography.body)
                                .foregroundStyle(PryTheme.Colors.deeplinks)
                        }
                        .padding(.horizontal, PryTheme.Spacing.md)
                        .padding(.vertical, PryTheme.Spacing.md)
                        .background(PryTheme.Colors.surface)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
        }
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            simulate()
        } label: {
            HStack {
                Image(systemName: sent ? "checkmark.circle.fill" : "link")
                    .font(PryTheme.Typography.body)
                Text(sent ? "Sent!" : "Open Deeplink")
                    .font(PryTheme.Typography.subheading)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PryTheme.Spacing.md)
            .background(sent ? PryTheme.Colors.success : PryTheme.Colors.deeplinks)
            .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
        }
        .disabled(isSendDisabled)
        .opacity(isSendDisabled ? PryTheme.Opacity.overlay : 1)
    }

    // MARK: - Components

    private func builderField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            fieldLabel(label)
            TextField(placeholder, text: text)
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(PryTheme.Spacing.md)
                .background(PryTheme.Colors.surface)
                .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: PryTheme.Radius.md)
                        .stroke(PryTheme.Colors.border, lineWidth: 1)
                )
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(PryTheme.Typography.detail)
            .fontWeight(.semibold)
            .textCase(.uppercase)
            .tracking(PryTheme.Text.tracking)
            .foregroundStyle(PryTheme.Colors.textSecondary)
    }

    private var isSendDisabled: Bool {
        if mode == .raw {
            return urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return scheme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    // MARK: - URL Building

    private func buildURL() -> String? {
        var components = URLComponents()
        components.scheme = scheme.trimmingCharacters(in: .whitespacesAndNewlines)

        let h = host.trimmingCharacters(in: .whitespacesAndNewlines)
        components.host = h.isEmpty ? nil : h

        let p = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if !p.isEmpty {
            components.path = p.hasPrefix("/") ? p : "/\(p)"
        }

        let validParams = queryParams
            .filter { !$0.key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { URLQueryItem(name: $0.key, value: $0.value.isEmpty ? nil : $0.value) }
        if !validParams.isEmpty {
            components.queryItems = validParams
        }

        return components.url?.absoluteString
    }

    // MARK: - Actions

    private func simulate() {
        let urlString: String
        if mode == .raw {
            urlString = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            guard let built = buildURL() else {
                validationError = "Could not build URL from fields"
                return
            }
            urlString = built
        }

        guard !urlString.isEmpty else { return }
        guard let url = URL(string: urlString), url.scheme != nil else {
            validationError = "Invalid URL. Must include a scheme (e.g. myapp:// or https://)"
            return
        }

        store.logDeeplink(url: url)
        openURL(url)

        // Update history (raw mode only)
        if mode == .raw {
            history.removeAll { $0 == urlString }
            history.insert(urlString, at: 0)
            if history.count > maxHistory {
                history = Array(history.prefix(maxHistory))
            }
        }

        validationError = nil

        withAnimation { sent = true }
        Task {
            try? await Task.sleep(for: PryTheme.Animation.toastDismiss)
            withAnimation { sent = false }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Simulator - Empty") {
    DeeplinkSimulatorView(store: PryStore())
        .presentationBackground(PryTheme.Colors.background)
}

#Preview("Simulator - With Store") {
    DeeplinkSimulatorView(store: .deeplinksOnly)
        .presentationBackground(PryTheme.Colors.background)
}
#endif
