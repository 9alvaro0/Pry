import SwiftUI

/// Form for creating or editing a mock rule.
struct MockRuleEditorView: View {

    @State private var rule: MockRule
    private let isEditing: Bool
    private let onSave: (MockRule) -> Void
    private let onCancel: () -> Void

    init(
        existingRule: MockRule? = nil,
        onSave: @escaping (MockRule) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._rule = State(initialValue: existingRule ?? MockRule())
        self.isEditing = existingRule != nil
        self.onSave = onSave
        self.onCancel = onCancel
    }

    private let methods = ["Any", "GET", "POST", "PUT", "DELETE", "PATCH"]

    @State private var statusCodeText = ""

    private var canSave: Bool {
        !rule.urlPattern.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        List {
            // Template buttons
            Section {
                templateButtons
            } header: {
                Text("Templates")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
            .listRowBackground(InspectorTheme.Colors.surface)

            // Basic info
            Section {
                formField("Name", placeholder: "Users - Success", text: $rule.name)
                formField("URL Pattern", placeholder: "/api/users", text: $rule.urlPattern)

                // Method picker
                HStack {
                    Text("Method")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(InspectorTheme.Colors.textSecondary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { rule.method ?? "Any" },
                        set: { rule.method = $0 == "Any" ? nil : $0 }
                    )) {
                        ForEach(methods, id: \.self) { method in
                            Text(method)
                                .tag(method)
                        }
                    }
                    .tint(InspectorTheme.Colors.accent)
                }
            } header: {
                Text("Matching")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
            .listRowBackground(InspectorTheme.Colors.surface)

            // Response config
            Section {
                // Status code
                HStack {
                    Text("Status Code")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(InspectorTheme.Colors.textSecondary)
                    Spacer()
                    TextField("200", text: $statusCodeText)
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.textPrimary)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: statusCodeText) { _, newValue in
                            if let code = Int(newValue) {
                                rule.statusCode = code
                            }
                        }
                }

                // Delay slider
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                    HStack {
                        Text("Delay")
                            .font(InspectorTheme.Typography.body)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)
                        Spacer()
                        Text(String(format: "%.1fs", rule.delay))
                            .font(InspectorTheme.Typography.code)
                            .foregroundStyle(InspectorTheme.Colors.textTertiary)
                    }
                    Slider(value: $rule.delay, in: 0...5, step: 0.5)
                        .tint(InspectorTheme.Colors.accent)
                }
            } header: {
                Text("Response")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
            .listRowBackground(InspectorTheme.Colors.surface)

            // Response body
            Section {
                TextEditor(text: Binding(
                    get: { rule.responseBody ?? "" },
                    set: { rule.responseBody = $0.isEmpty ? nil : $0 }
                ))
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 200)
                .overlay(alignment: .topLeading) {
                    if rule.responseBody == nil || rule.responseBody?.isEmpty == true {
                        Text("{\n  \"message\": \"Hello World\"\n}")
                            .font(InspectorTheme.Typography.code)
                            .foregroundStyle(InspectorTheme.Colors.textTertiary)
                            .allowsHitTesting(false)
                            .padding(.top, InspectorTheme.Spacing.sm)
                            .padding(.leading, InspectorTheme.Spacing.xs)
                    }
                }
            } header: {
                Text("Response Body")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
            .listRowBackground(InspectorTheme.Colors.surface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .inspectorBackground()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { onCancel() }
                    .foregroundStyle(InspectorTheme.Colors.textSecondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { onSave(rule) }
                    .fontWeight(.semibold)
                    .foregroundStyle(canSave ? InspectorTheme.Colors.accent : InspectorTheme.Colors.textTertiary)
                    .disabled(!canSave)
            }
        }
        .onAppear {
            statusCodeText = "\(rule.statusCode)"
        }
    }

    // MARK: - Templates

    private var templateButtons: some View {
        HStack(spacing: InspectorTheme.Spacing.sm) {
            templateButton("200 OK", statusCode: 200, body: "{\n  \"status\": \"ok\"\n}")
            templateButton("404 Not Found", statusCode: 404, body: "{\n  \"error\": \"Not found\"\n}")
            templateButton("500 Error", statusCode: 500, body: "{\n  \"error\": \"Internal server error\"\n}")
        }
    }

    private func templateButton(_ title: String, statusCode: Int, body: String) -> some View {
        Button {
            rule.statusCode = statusCode
            rule.responseBody = body
            statusCodeText = "\(statusCode)"
        } label: {
            Text(title)
                .font(InspectorTheme.Typography.detail)
                .fontWeight(.medium)
                .foregroundStyle(InspectorTheme.Colors.statusForeground(statusCode))
                .padding(.horizontal, InspectorTheme.Spacing.sm)
                .padding(.vertical, InspectorTheme.Spacing.xs)
                .background(InspectorTheme.Colors.statusBackground(statusCode))
                .clipShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Form Field

    private func formField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)
            TextField(placeholder, text: text)
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("New Rule") {
    NavigationStack {
        MockRuleEditorView(
            onSave: { _ in },
            onCancel: {}
        )
        .navigationTitle("New Mock Rule")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Edit Rule") {
    NavigationStack {
        MockRuleEditorView(
            existingRule: .mockUsersSuccess,
            onSave: { _ in },
            onCancel: {}
        )
        .navigationTitle("Edit Mock Rule")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
