import SwiftUI

/// Editor that appears when a request hits a breakpoint.
/// Shows editable URL, method, headers, and body. User taps Send or Cancel.
struct BreakpointEditorView: View {
    @Bindable var paused: PausedRequest
    let onSend: () -> Void
    let onCancel: () -> Void

    @State private var showAddHeader = false
    @State private var newHeaderKey = ""
    @State private var newHeaderValue = ""

    // Local state for response editing (avoids cursor reset from @Observable re-render)
    @State private var editStatusCode = ""
    @State private var editResponseBody = ""
    @State private var didInitResponseFields = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.lg) {
                    // Breakpoint indicator
                    breakpointBanner

                    if paused.isResponseBreakpoint {
                        responseEditor
                    } else {
                        requestEditor
                    }
                }
                .padding(.horizontal, PryTheme.Spacing.lg)
                .padding(.vertical, PryTheme.Spacing.md)
            }
            .pryBackground()
            .navigationTitle(paused.isResponseBreakpoint ? "Response Breakpoint" : "Request Breakpoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onCancel) {
                        Text("Drop")
                            .font(PryTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(PryTheme.Colors.error)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        syncResponseFieldsBack()
                        onSend()
                    } label: {
                        HStack(spacing: PryTheme.Spacing.xs) {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Send")
                        }
                        .font(PryTheme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(PryTheme.Colors.success)
                    }
                }
            }
        }
    }

    // MARK: - Breakpoint Banner

    private var breakpointBanner: some View {
        HStack(spacing: PryTheme.Spacing.sm) {
            Image(systemName: "pause.circle.fill")
                .font(PryTheme.Typography.body)
            Text("Request paused")
                .font(PryTheme.Typography.body)
                .fontWeight(.semibold)
            Spacer()
            Text(paused.rule.name.isEmpty ? paused.rule.urlPattern : paused.rule.name)
                .font(PryTheme.Typography.detail)
                .lineLimit(1)
        }
        .foregroundStyle(PryTheme.Colors.warning)
        .padding(PryTheme.Spacing.md)
        .background(PryTheme.Colors.warning.opacity(PryTheme.Opacity.tint))
        .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
    }

    // MARK: - Request Editor

    private var requestEditor: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.lg) {
            // URL
            editSection("URL") {
                TextField("URL", text: $paused.url)
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            // Method
            editSection("Method") {
                HStack(spacing: PryTheme.Spacing.sm) {
                    ForEach(["GET", "POST", "PUT", "DELETE", "PATCH"], id: \.self) { m in
                        Button {
                            paused.method = m
                        } label: {
                            Text(m)
                                .font(PryTheme.Typography.codeSmall)
                                .fontWeight(paused.method == m ? .bold : .regular)
                                .foregroundStyle(paused.method == m ? PryTheme.Colors.accent : PryTheme.Colors.textSecondary)
                                .padding(.horizontal, PryTheme.Spacing.sm)
                                .padding(.vertical, PryTheme.Spacing.xs)
                                .background(paused.method == m ? PryTheme.Colors.accent.opacity(PryTheme.Opacity.badge) : PryTheme.Colors.surface)
                                .clipShape(.capsule)
                        }
                    }
                }
            }

            // Headers
            editSection("Headers") {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                    ForEach(Array(paused.headers.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        HStack(alignment: .top, spacing: PryTheme.Spacing.sm) {
                            Text(key)
                                .font(PryTheme.Typography.code)
                                .foregroundStyle(PryTheme.Colors.syntaxKey)
                                .lineLimit(1)

                            TextField("value", text: headerBinding(for: key))
                                .font(PryTheme.Typography.code)
                                .foregroundStyle(PryTheme.Colors.textPrimary)

                            Button {
                                paused.headers.removeValue(forKey: key)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(PryTheme.Typography.detail)
                                    .foregroundStyle(PryTheme.Colors.textTertiary)
                            }
                        }
                    }

                    // Add header
                    if showAddHeader {
                        HStack(spacing: PryTheme.Spacing.sm) {
                            TextField("Key", text: $newHeaderKey)
                                .font(PryTheme.Typography.code)
                                .foregroundStyle(PryTheme.Colors.syntaxKey)
                            TextField("Value", text: $newHeaderValue)
                                .font(PryTheme.Typography.code)
                                .foregroundStyle(PryTheme.Colors.textPrimary)
                            Button {
                                if !newHeaderKey.isEmpty {
                                    paused.headers[newHeaderKey] = newHeaderValue
                                    newHeaderKey = ""
                                    newHeaderValue = ""
                                    showAddHeader = false
                                }
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(PryTheme.Colors.success)
                            }
                        }
                    } else {
                        Button {
                            showAddHeader = true
                        } label: {
                            HStack(spacing: PryTheme.Spacing.xs) {
                                Image(systemName: "plus.circle")
                                Text("Add Header")
                            }
                            .font(PryTheme.Typography.detail)
                            .foregroundStyle(PryTheme.Colors.accent)
                        }
                    }
                }
            }

            // Body
            bodyEditor(title: "Body", text: $paused.body)
        }
    }

    // MARK: - Response Editor

    private var responseEditor: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.lg) {
            // Original request info (read-only)
            HStack(spacing: PryTheme.Spacing.sm) {
                Text(paused.method)
                    .font(PryTheme.Typography.code)
                    .fontWeight(.semibold)
                    .foregroundStyle(PryTheme.Colors.textSecondary)

                Text(paused.url)
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(PryTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PryTheme.Colors.surface)
            .clipShape(.rect(cornerRadius: PryTheme.Radius.md))

            // Status code
            editSection("Status Code") {
                TextField("200", text: $editStatusCode)
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textPrimary)
                    .keyboardType(.numberPad)
            }

            // Response body
            bodyEditor(title: "Response Body", text: $editResponseBody)
        }
        .onAppear {
            guard !didInitResponseFields else { return }
            didInitResponseFields = true
            editStatusCode = paused.responseStatusCode.map(String.init) ?? "200"
            editResponseBody = Self.prettyPrintJSON(paused.responseBody ?? "")
        }
    }

    // MARK: - Helpers

    private func editSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            Text(title.uppercased())
                .font(PryTheme.Typography.sectionLabel)
                .tracking(PryTheme.Text.tracking)
                .foregroundStyle(PryTheme.Colors.textTertiary)

            content()
                .padding(PryTheme.Spacing.sm)
                .background(PryTheme.Colors.surface)
                .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: PryTheme.Radius.md)
                        .stroke(PryTheme.Colors.border, lineWidth: 1)
                )
        }
    }

    private func bodyEditor(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            HStack {
                Text(title.uppercased())
                    .font(PryTheme.Typography.sectionLabel)
                    .tracking(PryTheme.Text.tracking)
                    .foregroundStyle(PryTheme.Colors.textTertiary)

                Spacer()

                Button {
                    text.wrappedValue = Self.prettyPrintJSON(text.wrappedValue)
                } label: {
                    Text("Prettify")
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.accent)
                }
            }

            TextEditor(text: text)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .frame(minHeight: PryTheme.Size.editorMinHeight)
                .padding(PryTheme.Spacing.sm)
                .background(PryTheme.Colors.surface)
                .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: PryTheme.Radius.md)
                        .stroke(PryTheme.Colors.border, lineWidth: 1)
                )
        }
    }

    static func prettyPrintJSON(_ text: String) -> String {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let result = String(data: pretty, encoding: .utf8) else {
            return text
        }
        return result
    }

    private func syncResponseFieldsBack() {
        if paused.isResponseBreakpoint {
            paused.responseStatusCode = Int(editStatusCode)
            paused.responseBody = editResponseBody
        }
    }

    private func headerBinding(for key: String) -> Binding<String> {
        Binding(
            get: { paused.headers[key] ?? "" },
            set: { paused.headers[key] = $0 }
        )
    }
}
