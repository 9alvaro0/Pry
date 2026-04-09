import SwiftUI
import UIKit

struct DeeplinkSimulatorView: View {
    @Bindable var store: PryStore

    @Environment(\.dismiss) private var dismiss

    @State private var urlInput: String = ""
    @State private var history: [String] = []
    @State private var validationError: String?
    @State private var sent = false

    private let maxHistory = 5

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.lg) {
                    urlSection

                    if !history.isEmpty {
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

    // MARK: - URL Section

    private var urlSection: some View {
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
                .onChange(of: urlInput) {
                    validationError = nil
                }

            if let error = validationError {
                Text(error)
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.error)
            }

            Text("Use any scheme registered by your app, or a Universal Link.")
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)
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
                        simulateURL()
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
            simulateURL()
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

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(PryTheme.Typography.detail)
            .fontWeight(.semibold)
            .textCase(.uppercase)
            .tracking(PryTheme.Text.tracking)
            .foregroundStyle(PryTheme.Colors.textSecondary)
    }

    private var isSendDisabled: Bool {
        urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

        // Open the URL so the app actually receives it
        Task { @MainActor in
            if UIApplication.shared.canOpenURL(url) {
                await UIApplication.shared.open(url)
            }
        }

        // Update history
        history.removeAll { $0 == trimmed }
        history.insert(trimmed, at: 0)
        if history.count > maxHistory {
            history = Array(history.prefix(maxHistory))
        }

        validationError = nil

        // Visual feedback
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
