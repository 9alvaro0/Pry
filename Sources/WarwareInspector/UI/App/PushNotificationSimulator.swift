import SwiftUI

struct PushNotificationSimulatorView: View {
    @Bindable var store: InspectorStore

    @Environment(\.dismiss) private var dismiss

    @State private var titleInput: String = ""
    @State private var bodyInput: String = ""
    @State private var categoryInput: String = ""
    @State private var history: [(title: String, body: String)] = []

    private let maxHistory = 3

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Input section
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
                    fieldLabel("Title")

                    TextField("Flash Sale!", text: $titleInput)
                        .font(InspectorTheme.Typography.code)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(InspectorTheme.Spacing.md)
                        .background(InspectorTheme.Colors.surface)
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: InspectorTheme.Radius.md)
                                .stroke(InspectorTheme.Colors.border, lineWidth: 1)
                        )

                    fieldLabel("Body")

                    TextField("50% off all items!", text: $bodyInput)
                        .font(InspectorTheme.Typography.code)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(InspectorTheme.Spacing.md)
                        .background(InspectorTheme.Colors.surface)
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: InspectorTheme.Radius.md)
                                .stroke(InspectorTheme.Colors.border, lineWidth: 1)
                        )

                    fieldLabel("Category (optional)")

                    TextField("PROMO", text: $categoryInput)
                        .font(InspectorTheme.Typography.code)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(InspectorTheme.Spacing.md)
                        .background(InspectorTheme.Colors.surface)
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: InspectorTheme.Radius.md)
                                .stroke(InspectorTheme.Colors.border, lineWidth: 1)
                        )

                    Button {
                        simulate()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(InspectorTheme.Typography.detail)
                            Text("Simulate")
                                .font(InspectorTheme.Typography.subheading)
                        }
                        .foregroundStyle(InspectorTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, InspectorTheme.Spacing.md)
                        .background(InspectorTheme.Colors.warning)
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                    }
                    .disabled(isInputEmpty)
                    .opacity(isInputEmpty ? 0.5 : 1)
                }
                .padding(InspectorTheme.Spacing.lg)

                // History section
                if !history.isEmpty {
                    VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
                        Text("Recent")
                            .font(InspectorTheme.Typography.detail)
                            .fontWeight(.semibold)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)
                            .padding(.horizontal, InspectorTheme.Spacing.lg)

                        ScrollView {
                            VStack(spacing: 1) {
                                ForEach(Array(history.enumerated()), id: \.offset) { _, item in
                                    Button {
                                        titleInput = item.title
                                        bodyInput = item.body
                                        simulate()
                                    } label: {
                                        HStack {
                                            Image(systemName: "arrow.counterclockwise")
                                                .font(InspectorTheme.Typography.detail)
                                                .foregroundStyle(InspectorTheme.Colors.textTertiary)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.title.isEmpty ? "No Title" : item.title)
                                                    .font(InspectorTheme.Typography.codeSmall)
                                                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                                                    .lineLimit(1)

                                                if !item.body.isEmpty {
                                                    Text(item.body)
                                                        .font(InspectorTheme.Typography.detail)
                                                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                                                        .lineLimit(1)
                                                }
                                            }

                                            Spacer()

                                            Image(systemName: "play.circle")
                                                .font(InspectorTheme.Typography.body)
                                                .foregroundStyle(InspectorTheme.Colors.warning)
                                        }
                                        .padding(.horizontal, InspectorTheme.Spacing.lg)
                                        .padding(.vertical, InspectorTheme.Spacing.md)
                                        .background(InspectorTheme.Colors.surface)
                                        .contentShape(.rect)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                            .padding(.horizontal, InspectorTheme.Spacing.lg)
                        }
                    }
                }

                Spacer()
            }
            .inspectorBackground()
            .navigationTitle("Simulate Push")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(InspectorTheme.Typography.body)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var isInputEmpty: Bool {
        titleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        bodyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(InspectorTheme.Typography.detail)
            .fontWeight(.semibold)
            .textCase(.uppercase)
            .tracking(0.5)
            .foregroundStyle(InspectorTheme.Colors.textSecondary)
    }

    // MARK: - Actions

    private func simulate() {
        let title = titleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = bodyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = categoryInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty || !body.isEmpty else { return }

        store.logPushNotification(
            title: title.isEmpty ? nil : title,
            body: body.isEmpty ? nil : body,
            subtitle: nil,
            badge: nil,
            sound: nil,
            categoryIdentifier: category.isEmpty ? nil : category,
            threadIdentifier: nil,
            userInfo: [:]
        )

        // Update history
        let item = (title: title, body: body)
        history.removeAll { $0.title == title && $0.body == body }
        history.insert(item, at: 0)
        if history.count > maxHistory {
            history = Array(history.prefix(maxHistory))
        }

        titleInput = ""
        bodyInput = ""
        categoryInput = ""
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Simulator - Empty") {
    PushNotificationSimulatorView(store: InspectorStore())
        .presentationBackground(InspectorTheme.Colors.background)
}

#Preview("Simulator - With Store") {
    PushNotificationSimulatorView(store: .pushOnly)
        .presentationBackground(InspectorTheme.Colors.background)
}
#endif
