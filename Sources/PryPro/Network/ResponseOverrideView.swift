import SwiftUI

/// Editor to override a network response. Pre-filled with the actual response.
/// Save creates a mock rule and enables it automatically.
struct ResponseOverrideView: View {
    let entry: NetworkEntry
    @Environment(\.pryProStore) private var proStore
    @Environment(\.dismiss) private var dismiss

    @State private var statusCode: String
    @State private var responseBody: String
    @State private var delay: Double = 0
    @State private var saved = false

    /// Whether this entry already has an active override.
    private var existingRule: MockRule? {
        proStore?.mockRules.first { $0.urlPattern == entry.requestURL.extractPath() && $0.method == entry.requestMethod }
    }

    init(entry: NetworkEntry) {
        self.entry = entry
        self._statusCode = State(initialValue: "\(entry.responseStatusCode ?? 200)")
        self._responseBody = State(initialValue: entry.responseBody ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.lg) {
                    // What you're overriding
                    requestSummary

                    // Status code
                    VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                        sectionLabel("Status Code")

                        HStack(spacing: PryTheme.Spacing.sm) {
                            quickStatus(200, label: "200")
                            quickStatus(201, label: "201")
                            quickStatus(400, label: "400")
                            quickStatus(404, label: "404")
                            quickStatus(500, label: "500")

                            TextField("200", text: $statusCode)
                                .font(PryTheme.Typography.code)
                                .foregroundStyle(PryTheme.Colors.textPrimary)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .multilineTextAlignment(.center)
                                .padding(PryTheme.Spacing.sm)
                                .background(PryTheme.Colors.surface)
                                .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))
                                .overlay(
                                    RoundedRectangle(cornerRadius: PryTheme.Radius.sm)
                                        .stroke(PryTheme.Colors.border, lineWidth: 1)
                                )
                        }
                    }

                    // Response body editor
                    VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                        sectionLabel("Response Body")

                        TextEditor(text: $responseBody)
                            .font(PryTheme.Typography.code)
                            .foregroundStyle(PryTheme.Colors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: PryTheme.Size.editorMinHeight)
                            .padding(PryTheme.Spacing.sm)
                            .background(PryTheme.Colors.surface)
                            .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: PryTheme.Radius.md)
                                    .stroke(PryTheme.Colors.border, lineWidth: 1)
                            )
                    }

                    // Delay
                    VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                        HStack {
                            sectionLabel("Delay")
                            Spacer()
                            Text(delay == 0 ? "Instant" : String(format: "%.1fs", delay))
                                .font(PryTheme.Typography.code)
                                .foregroundStyle(PryTheme.Colors.textSecondary)
                        }
                        Slider(value: $delay, in: 0...5, step: 0.5)
                            .tint(PryTheme.Colors.accent)
                    }

                    // Remove override (if exists)
                    if let rule = existingRule {
                        Button(role: .destructive) {
                            proStore?.removeMockRule(rule.id)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Remove Mock")
                            }
                            .font(PryTheme.Typography.body)
                            .foregroundStyle(PryTheme.Colors.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, PryTheme.Spacing.md)
                            .background(PryTheme.Colors.error.opacity(PryTheme.Opacity.border))
                            .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                        }
                    }
                }
                .padding(PryTheme.Spacing.lg)
            }
            .pryBackground()
            .navigationTitle("Mock Response")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(PryTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { save() } label: {
                        Image(systemName: saved ? "checkmark.circle.fill" : "checkmark")
                            .font(PryTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(saved ? PryTheme.Colors.success : PryTheme.Colors.accent)
                    }
                }
            }
        }
    }

    // MARK: - Request Summary

    private var requestSummary: some View {
        HStack(spacing: PryTheme.Spacing.sm) {
            Text(entry.requestMethod)
                .font(PryTheme.Typography.code)
                .fontWeight(.semibold)
                .foregroundStyle(PryTheme.Colors.textSecondary)

            Text(entry.requestURL.extractPath())
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(PryTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PryTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(PryTheme.Typography.detail)
            .fontWeight(.semibold)
            .textCase(.uppercase)
            .tracking(PryTheme.Text.tracking)
            .foregroundStyle(PryTheme.Colors.textSecondary)
    }

    private func quickStatus(_ code: Int, label: String) -> some View {
        Button {
            statusCode = "\(code)"
        } label: {
            Text(label)
                .font(PryTheme.Typography.codeSmall)
                .fontWeight(.medium)
                .foregroundStyle(
                    statusCode == "\(code)"
                        ? PryTheme.Colors.statusForeground(code)
                        : PryTheme.Colors.textTertiary
                )
                .padding(.horizontal, PryTheme.Spacing.sm)
                .padding(.vertical, PryTheme.Spacing.xs)
                .background(
                    statusCode == "\(code)"
                        ? PryTheme.Colors.statusBackground(code)
                        : PryTheme.Colors.surface
                )
                .clipShape(.capsule)
        }
    }

    // MARK: - Save

    private func save() {
        let code = Int(statusCode) ?? 200

        // Remove existing rule for same path+method
        if let existing = existingRule {
            proStore?.removeMockRule(existing.id)
        }

        let rule = MockRule(
            name: "\(entry.requestMethod) \(entry.requestURL.extractPath())",
            urlPattern: entry.requestURL.extractPath(),
            method: entry.requestMethod,
            statusCode: code,
            responseBody: responseBody.isEmpty ? nil : responseBody,
            responseHeaders: entry.responseHeaders ?? ["Content-Type": "application/json"],
            delay: delay
        )

        proStore?.addMockRule(rule)

        withAnimation { saved = true }
        Task {
            try? await Task.sleep(for: PryTheme.Animation.feedbackDelay)
            dismiss()
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Override - Success") {
    ResponseOverrideView(entry: .mockSuccess)
        .environment(\.pryStore, .preview)
}

#Preview("Override - Error") {
    ResponseOverrideView(entry: .mockError)
        .environment(\.pryStore, .preview)
}
#endif
