import SwiftUI

struct DeeplinkSimulatorView: View {
    @Bindable var store: PryStore

    @Environment(\.dismiss) private var dismiss

    @State private var urlInput: String = ""
    @State private var history: [String] = []
    @State private var validationError: String?

    private let maxHistory = 5

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Input section
                VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                    Text("URL")
                        .font(PryTheme.Typography.detail)
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                        .tracking(PryTheme.Text.tracking)
                        .foregroundStyle(PryTheme.Colors.textSecondary)

                    TextField("myapp://rooms/open?roomId=42", text: $urlInput)
                        .font(PryTheme.Typography.code)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .padding(PryTheme.Spacing.md)
                        .background(PryTheme.Colors.surface)
                        .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: PryTheme.Radius.md)
                                .stroke(
                                    validationError != nil
                                        ? PryTheme.Colors.error.opacity(PryTheme.Opacity.overlay)
                                        : PryTheme.Colors.border,
                                    lineWidth: 1
                                )
                        )
                        .onChange(of: urlInput) {
                            validationError = nil
                        }

                    if let error = validationError {
                        Text(error)
                            .font(PryTheme.Typography.detail)
                            .foregroundStyle(PryTheme.Colors.error)
                    }

                    Button {
                        simulateURL()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(PryTheme.Typography.detail)
                            Text("Simulate")
                                .font(PryTheme.Typography.subheading)
                        }
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PryTheme.Spacing.md)
                        .background(PryTheme.Colors.deeplinks)
                        .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                    }
                    .disabled(urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? PryTheme.Opacity.overlay : 1)
                }
                .padding(PryTheme.Spacing.lg)

                // History section
                if !history.isEmpty {
                    VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                        Text("Recent")
                            .font(PryTheme.Typography.detail)
                            .fontWeight(.semibold)
                            .textCase(.uppercase)
                            .tracking(PryTheme.Text.tracking)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
                            .padding(.horizontal, PryTheme.Spacing.lg)

                        ScrollView {
                            VStack(spacing: 1) {
                                ForEach(history, id: \.self) { url in
                                    Button {
                                        urlInput = url
                                        simulateURL()
                                    } label: {
                                        HStack {
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
                                        .padding(.horizontal, PryTheme.Spacing.lg)
                                        .padding(.vertical, PryTheme.Spacing.md)
                                        .background(PryTheme.Colors.surface)
                                        .contentShape(.rect)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                            .padding(.horizontal, PryTheme.Spacing.lg)
                        }
                    }
                }

                Spacer()
            }
            .pryBackground()
            .navigationTitle("Simulate Deeplink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(PryTheme.Typography.body)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
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
    DeeplinkSimulatorView(store: PryStore())
        .presentationBackground(PryTheme.Colors.background)
}

#Preview("Simulator - With Store") {
    DeeplinkSimulatorView(store: .deeplinksOnly)
        .presentationBackground(PryTheme.Colors.background)
}
#endif
