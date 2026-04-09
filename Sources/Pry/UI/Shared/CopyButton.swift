import SwiftUI
import UIKit

/// Copy-to-clipboard button with visual feedback.
///
/// Two styles:
/// - `.iconOnly` (default) — just the icon, 36x36 tap target, for toolbars/headers
/// - `.labeled` — icon + text, for inline use
package struct CopyButtonView: View {

    package enum Style {
        case iconOnly
        case labeled(String, copiedLabel: String)
    }

    package let valueToCopy: String
    package var style: Style = .iconOnly

    @State private var isCopied = false

    package var body: some View {
        Button {
            Task { await copy() }
        } label: {
            switch style {
            case .iconOnly:
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(isCopied ? PryTheme.Colors.success : PryTheme.Colors.textSecondary)
                    .frame(width: PryTheme.Size.iconLarge, height: PryTheme.Size.iconLarge)
                    .contentShape(.rect)

            case .labeled(let title, let copiedLabel):
                HStack(spacing: PryTheme.Spacing.xs) {
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(PryTheme.Typography.detail)
                    Text(isCopied ? copiedLabel : title)
                        .font(PryTheme.Typography.detail)
                }
                .foregroundStyle(isCopied ? PryTheme.Colors.success : PryTheme.Colors.accent)
            }
        }
        .buttonStyle(.plain)
        .disabled(isCopied)
    }

    private func copy() async {
        UIPasteboard.general.string = valueToCopy
        withAnimation { isCopied = true }
        try? await Task.sleep(for: PryTheme.Animation.toastDismiss)
        withAnimation { isCopied = false }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Icon Only") {
    HStack(spacing: PryTheme.Spacing.lg) {
        CopyButtonView(valueToCopy: "test")
        CopyButtonView(valueToCopy: "test")
        CopyButtonView(valueToCopy: "test")
    }
    .padding()
    .pryBackground()
}

#Preview("Labeled") {
    VStack(spacing: PryTheme.Spacing.lg) {
        CopyButtonView(
            valueToCopy: "Bearer eyJ0eXAi...",
            style: .labeled("Copy Token", copiedLabel: "Copied!")
        )
        CopyButtonView(
            valueToCopy: "https://api.example.com",
            style: .labeled("Copy URL", copiedLabel: "Copied!")
        )
    }
    .padding()
    .pryBackground()
}
#endif
