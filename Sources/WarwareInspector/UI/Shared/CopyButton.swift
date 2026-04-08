import SwiftUI
import UIKit

/// Copy-to-clipboard button with visual feedback.
///
/// Two styles:
/// - `.iconOnly` (default) — just the icon, 36x36 tap target, for toolbars/headers
/// - `.labeled` — icon + text, for inline use
struct CopyButtonView: View {

    enum Style {
        case iconOnly
        case labeled(String, copiedLabel: String)
    }

    let valueToCopy: String
    var style: Style = .iconOnly

    @State private var isCopied = false

    var body: some View {
        Button {
            Task { await copy() }
        } label: {
            switch style {
            case .iconOnly:
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(InspectorTheme.Typography.body)
                    .foregroundStyle(isCopied ? InspectorTheme.Colors.success : InspectorTheme.Colors.textSecondary)
                    .frame(width: InspectorTheme.Size.iconLarge, height: InspectorTheme.Size.iconLarge)
                    .contentShape(.rect)

            case .labeled(let title, let copiedLabel):
                HStack(spacing: InspectorTheme.Spacing.xs) {
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(InspectorTheme.Typography.detail)
                    Text(isCopied ? copiedLabel : title)
                        .font(InspectorTheme.Typography.detail)
                }
                .foregroundStyle(isCopied ? InspectorTheme.Colors.success : InspectorTheme.Colors.accent)
            }
        }
        .buttonStyle(.plain)
        .disabled(isCopied)
    }

    private func copy() async {
        UIPasteboard.general.string = valueToCopy
        withAnimation { isCopied = true }
        try? await Task.sleep(for: InspectorTheme.Animation.toastDismiss)
        withAnimation { isCopied = false }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Icon Only") {
    HStack(spacing: InspectorTheme.Spacing.lg) {
        CopyButtonView(valueToCopy: "test")
        CopyButtonView(valueToCopy: "test")
        CopyButtonView(valueToCopy: "test")
    }
    .padding()
    .inspectorBackground()
}

#Preview("Labeled") {
    VStack(spacing: InspectorTheme.Spacing.lg) {
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
    .inspectorBackground()
}
#endif
