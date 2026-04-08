import SwiftUI

struct DeeplinkSimulatorView: View {
    @Bindable var store: InspectorStore

    @Environment(\.dismiss) private var dismiss

    @State private var urlInput: String = ""
    @State private var history: [String] = []
    @State private var validationError: String?

    private let maxHistory = 5

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Input section
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
                    Text("URL")
                        .font(InspectorTheme.Typography.detail)
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                        .tracking(InspectorTheme.Text.tracking)
                        .foregroundStyle(InspectorTheme.Colors.textSecondary)

                    TextField("myapp://rooms/open?roomId=42", text: $urlInput)
                        .font(InspectorTheme.Typography.code)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .padding(InspectorTheme.Spacing.md)
                        .background(InspectorTheme.Colors.surface)
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: InspectorTheme.Radius.md)
                                .stroke(
                                    validationError != nil
                                        ? InspectorTheme.Colors.error.opacity(InspectorTheme.Opacity.overlay)
                                        : InspectorTheme.Colors.border,
                                    lineWidth: 1
                                )
                        )
                        .onChange(of: urlInput) {
                            validationError = nil
                        }

                    if let error = validationError {
                        Text(error)
                            .font(InspectorTheme.Typography.detail)
                            .foregroundStyle(InspectorTheme.Colors.error)
                    }

                    Button {
                        simulateURL()
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
                        .background(InspectorTheme.Colors.deeplinks)
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                    }
                    .disabled(urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? InspectorTheme.Opacity.overlay : 1)
                }
                .padding(InspectorTheme.Spacing.lg)

                // History section
                if !history.isEmpty {
                    VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
                        Text("Recent")
                            .font(InspectorTheme.Typography.detail)
                            .fontWeight(.semibold)
                            .textCase(.uppercase)
                            .tracking(InspectorTheme.Text.tracking)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)
                            .padding(.horizontal, InspectorTheme.Spacing.lg)

                        ScrollView {
                            VStack(spacing: 1) {
                                ForEach(history, id: \.self) { url in
                                    Button {
                                        urlInput = url
                                        simulateURL()
                                    } label: {
                                        HStack {
                                            Image(systemName: "arrow.counterclockwise")
                                                .font(InspectorTheme.Typography.detail)
                                                .foregroundStyle(InspectorTheme.Colors.textTertiary)

                                            Text(url)
                                                .font(InspectorTheme.Typography.codeSmall)
                                                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)

                                            Spacer()

                                            Image(systemName: "play.circle")
                                                .font(InspectorTheme.Typography.body)
                                                .foregroundStyle(InspectorTheme.Colors.deeplinks)
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
            .navigationTitle("Simulate Deeplink")
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

    // MARK: - Actions

    private func simulateURL() {
        let trimmed = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let url = URL(string: trimmed), url.scheme != nil else {
            validationError = "Invalid URL. Must include a scheme (e.g. myapp:// or https://)"
            return
        }

        store.logDeeplink(url: url)

        // Update history
        history.removeAll { $0 == trimmed }
        history.insert(trimmed, at: 0)
        if history.count > maxHistory {
            history = Array(history.prefix(maxHistory))
        }

        urlInput = ""
        validationError = nil
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Simulator - Empty") {
    DeeplinkSimulatorView(store: InspectorStore())
        .presentationBackground(InspectorTheme.Colors.background)
}

#Preview("Simulator - With Store") {
    DeeplinkSimulatorView(store: .deeplinksOnly)
        .presentationBackground(InspectorTheme.Colors.background)
}
#endif
