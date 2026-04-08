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
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.lg) {
                    // Breakpoint indicator
                    breakpointBanner

                    if paused.isResponseBreakpoint {
                        responseEditor
                    } else {
                        requestEditor
                    }
                }
                .padding(.horizontal, InspectorTheme.Spacing.lg)
                .padding(.vertical, InspectorTheme.Spacing.md)
            }
            .inspectorBackground()
            .navigationTitle(paused.isResponseBreakpoint ? "Response Breakpoint" : "Request Breakpoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onCancel) {
                        Text("Drop")
                            .font(InspectorTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(InspectorTheme.Colors.error)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        syncResponseFieldsBack()
                        onSend()
                    } label: {
                        HStack(spacing: InspectorTheme.Spacing.xs) {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Send")
                        }
                        .font(InspectorTheme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(InspectorTheme.Colors.success)
                    }
                }
            }
        }
    }

    // MARK: - Breakpoint Banner

    private var breakpointBanner: some View {
        HStack(spacing: InspectorTheme.Spacing.sm) {
            Image(systemName: "pause.circle.fill")
                .font(InspectorTheme.Typography.body)
            Text("Request paused")
                .font(InspectorTheme.Typography.body)
                .fontWeight(.semibold)
            Spacer()
            Text(paused.rule.name.isEmpty ? paused.rule.urlPattern : paused.rule.name)
                .font(InspectorTheme.Typography.detail)
                .lineLimit(1)
        }
        .foregroundStyle(InspectorTheme.Colors.warning)
        .padding(InspectorTheme.Spacing.md)
        .background(InspectorTheme.Colors.warning.opacity(InspectorTheme.Opacity.tint))
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
    }

    // MARK: - Request Editor

    private var requestEditor: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.lg) {
            // URL
            editSection("URL") {
                TextField("URL", text: $paused.url)
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            // Method
            editSection("Method") {
                HStack(spacing: InspectorTheme.Spacing.sm) {
                    ForEach(["GET", "POST", "PUT", "DELETE", "PATCH"], id: \.self) { m in
                        Button {
                            paused.method = m
                        } label: {
                            Text(m)
                                .font(InspectorTheme.Typography.codeSmall)
                                .fontWeight(paused.method == m ? .bold : .regular)
                                .foregroundStyle(paused.method == m ? InspectorTheme.Colors.accent : InspectorTheme.Colors.textSecondary)
                                .padding(.horizontal, InspectorTheme.Spacing.sm)
                                .padding(.vertical, InspectorTheme.Spacing.xs)
                                .background(paused.method == m ? InspectorTheme.Colors.accent.opacity(InspectorTheme.Opacity.badge) : InspectorTheme.Colors.surface)
                                .clipShape(.capsule)
                        }
                    }
                }
            }

            // Headers
            editSection("Headers") {
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
                    ForEach(Array(paused.headers.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        HStack(alignment: .top, spacing: InspectorTheme.Spacing.sm) {
                            Text(key)
                                .font(InspectorTheme.Typography.code)
                                .foregroundStyle(InspectorTheme.Colors.syntaxKey)
                                .lineLimit(1)

                            TextField("value", text: headerBinding(for: key))
                                .font(InspectorTheme.Typography.code)
                                .foregroundStyle(InspectorTheme.Colors.textPrimary)

                            Button {
                                paused.headers.removeValue(forKey: key)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(InspectorTheme.Typography.detail)
                                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
                            }
                        }
                    }

                    // Add header
                    if showAddHeader {
                        HStack(spacing: InspectorTheme.Spacing.sm) {
                            TextField("Key", text: $newHeaderKey)
                                .font(InspectorTheme.Typography.code)
                                .foregroundStyle(InspectorTheme.Colors.syntaxKey)
                            TextField("Value", text: $newHeaderValue)
                                .font(InspectorTheme.Typography.code)
                                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                            Button {
                                if !newHeaderKey.isEmpty {
                                    paused.headers[newHeaderKey] = newHeaderValue
                                    newHeaderKey = ""
                                    newHeaderValue = ""
                                    showAddHeader = false
                                }
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(InspectorTheme.Colors.success)
                            }
                        }
                    } else {
                        Button {
                            showAddHeader = true
                        } label: {
                            HStack(spacing: InspectorTheme.Spacing.xs) {
                                Image(systemName: "plus.circle")
                                Text("Add Header")
                            }
                            .font(InspectorTheme.Typography.detail)
                            .foregroundStyle(InspectorTheme.Colors.accent)
                        }
                    }
                }
            }

            // Body
            editSection("Body") {
                TextEditor(text: $paused.body)
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: InspectorTheme.Size.editorMinHeight)
            }
        }
    }

    // MARK: - Response Editor

    private var responseEditor: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.lg) {
            // Original request info (read-only)
            HStack(spacing: InspectorTheme.Spacing.sm) {
                Text(paused.method)
                    .font(InspectorTheme.Typography.code)
                    .fontWeight(.semibold)
                    .foregroundStyle(InspectorTheme.Colors.textSecondary)

                Text(paused.url)
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(InspectorTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(InspectorTheme.Colors.surface)
            .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))

            // Status code
            editSection("Status Code") {
                TextField("200", text: $editStatusCode)
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    .keyboardType(.numberPad)
            }

            // Response body
            editSection("Response Body") {
                TextEditor(text: $editResponseBody)
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: InspectorTheme.Size.editorMinHeight)
            }
        }
        .onAppear {
            guard !didInitResponseFields else { return }
            didInitResponseFields = true
            editStatusCode = paused.responseStatusCode.map(String.init) ?? "200"
            editResponseBody = paused.responseBody ?? ""
        }
    }

    // MARK: - Helpers

    private func editSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
            Text(title.uppercased())
                .font(InspectorTheme.Typography.sectionLabel)
                .tracking(InspectorTheme.Text.tracking)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)

            content()
                .padding(InspectorTheme.Spacing.sm)
                .background(InspectorTheme.Colors.surface)
                .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: InspectorTheme.Radius.md)
                        .stroke(InspectorTheme.Colors.border, lineWidth: 1)
                )
        }
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
