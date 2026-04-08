import SwiftUI

/// Editor to override a network response. Pre-filled with the actual response.
/// Save creates a mock rule and enables it automatically.
struct ResponseOverrideView: View {
    let entry: NetworkEntry
    @Environment(\.inspectorStore) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var statusCode: String
    @State private var removed = false
    @State private var responseBody: String
    @State private var delay: Double = 0
    @State private var saved = false

    /// Whether this entry already has an active override.
    private var existingRule: MockRule? {
        store.mockRules.first { $0.urlPattern == entry.requestURL.extractPath() && $0.method == entry.requestMethod }
    }

    init(entry: NetworkEntry) {
        self.entry = entry
        self._statusCode = State(initialValue: "\(entry.responseStatusCode ?? 200)")
        self._responseBody = State(initialValue: entry.responseBody ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.lg) {
                    // What you're overriding
                    requestSummary

                    // Status code
                    VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                        sectionLabel("Status Code")

                        HStack(spacing: InspectorTheme.Spacing.sm) {
                            quickStatus(200, label: "200")
                            quickStatus(201, label: "201")
                            quickStatus(400, label: "400")
                            quickStatus(404, label: "404")
                            quickStatus(500, label: "500")

                            TextField("200", text: $statusCode)
                                .font(InspectorTheme.Typography.code)
                                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .multilineTextAlignment(.center)
                                .padding(InspectorTheme.Spacing.sm)
                                .background(InspectorTheme.Colors.surface)
                                .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))
                                .overlay(
                                    RoundedRectangle(cornerRadius: InspectorTheme.Radius.sm)
                                        .stroke(InspectorTheme.Colors.border, lineWidth: 1)
                                )
                        }
                    }

                    // Response body editor
                    VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                        sectionLabel("Response Body")

                        TextEditor(text: $responseBody)
                            .font(InspectorTheme.Typography.code)
                            .foregroundStyle(InspectorTheme.Colors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 250)
                            .padding(InspectorTheme.Spacing.sm)
                            .background(InspectorTheme.Colors.surface)
                            .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: InspectorTheme.Radius.md)
                                    .stroke(InspectorTheme.Colors.border, lineWidth: 1)
                            )
                    }

                    // Delay
                    VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                        HStack {
                            sectionLabel("Delay")
                            Spacer()
                            Text(delay == 0 ? "Instant" : String(format: "%.1fs", delay))
                                .font(InspectorTheme.Typography.code)
                                .foregroundStyle(InspectorTheme.Colors.textSecondary)
                        }
                        Slider(value: $delay, in: 0...5, step: 0.5)
                            .tint(InspectorTheme.Colors.accent)
                    }

                    // Remove override (if exists)
                    if let rule = existingRule {
                        Button(role: .destructive) {
                            store.removeMockRule(rule.id)
                            removed = true
                            Task {
                                try? await Task.sleep(for: .seconds(1))
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Remove Mock")
                            }
                            .font(InspectorTheme.Typography.body)
                            .foregroundStyle(InspectorTheme.Colors.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, InspectorTheme.Spacing.md)
                            .background(InspectorTheme.Colors.error.opacity(0.1))
                            .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                        }
                    }
                }
                .padding(InspectorTheme.Spacing.lg)
            }
            .inspectorBackground()
            .overlay(alignment: .top) {
                if removed {
                    Text("Mock removed")
                        .font(InspectorTheme.Typography.detail)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, InspectorTheme.Spacing.md)
                        .padding(.vertical, InspectorTheme.Spacing.xs)
                        .background(InspectorTheme.Colors.error)
                        .clipShape(.capsule)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, InspectorTheme.Spacing.sm)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: removed)
            .navigationTitle("Mock Response")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(InspectorTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { save() } label: {
                        Image(systemName: saved ? "checkmark.circle.fill" : "checkmark")
                            .font(InspectorTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(saved ? InspectorTheme.Colors.success : InspectorTheme.Colors.accent)
                    }
                }
            }
        }
    }

    // MARK: - Request Summary

    private var requestSummary: some View {
        HStack(spacing: InspectorTheme.Spacing.sm) {
            Text(entry.requestMethod)
                .font(InspectorTheme.Typography.code)
                .fontWeight(.semibold)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)

            Text(entry.requestURL.extractPath())
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(InspectorTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(InspectorTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(InspectorTheme.Typography.detail)
            .fontWeight(.semibold)
            .textCase(.uppercase)
            .tracking(0.5)
            .foregroundStyle(InspectorTheme.Colors.textSecondary)
    }

    private func quickStatus(_ code: Int, label: String) -> some View {
        Button {
            statusCode = "\(code)"
        } label: {
            Text(label)
                .font(InspectorTheme.Typography.codeSmall)
                .fontWeight(.medium)
                .foregroundStyle(
                    statusCode == "\(code)"
                        ? InspectorTheme.Colors.statusForeground(code)
                        : InspectorTheme.Colors.textTertiary
                )
                .padding(.horizontal, InspectorTheme.Spacing.sm)
                .padding(.vertical, InspectorTheme.Spacing.xs)
                .background(
                    statusCode == "\(code)"
                        ? InspectorTheme.Colors.statusBackground(code)
                        : InspectorTheme.Colors.surface
                )
                .clipShape(.capsule)
        }
    }

    // MARK: - Save

    private func save() {
        let code = Int(statusCode) ?? 200

        // Remove existing rule for same path+method
        if let existing = existingRule {
            store.removeMockRule(existing.id)
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

        store.addMockRule(rule)

        withAnimation { saved = true }
        Task {
            try? await Task.sleep(for: .seconds(1))
            dismiss()
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Override - Success") {
    ResponseOverrideView(entry: .mockSuccess)
        .environment(\.inspectorStore, .preview)
}

#Preview("Override - Error") {
    ResponseOverrideView(entry: .mockError)
        .environment(\.inspectorStore, .preview)
}
#endif
