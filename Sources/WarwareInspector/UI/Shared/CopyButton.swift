import SwiftUI
import UIKit

struct CopyButtonView: View {
    let title: String
    let copiedTitle: String
    let valueToCopy: String

    @State private var isCopied = false

    init(
        title: String = "Copy",
        copiedTitle: String = "Copied!",
        valueToCopy: String
    ) {
        self.title = title
        self.copiedTitle = copiedTitle
        self.valueToCopy = valueToCopy
    }

    var body: some View {
        Button {
            Task { await copy() }
        } label: {
            HStack(spacing: InspectorTheme.Spacing.xs) {
                Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(InspectorTheme.Typography.detail)
                Text(isCopied ? copiedTitle : title)
                    .font(InspectorTheme.Typography.detail)
            }
            .foregroundStyle(isCopied ? InspectorTheme.Colors.success : InspectorTheme.Colors.accent)
        }
        .disabled(isCopied)
    }

    private func copy() async {
        UIPasteboard.general.string = valueToCopy
        withAnimation { isCopied = true }
        try? await Task.sleep(for: .seconds(2))
        withAnimation { isCopied = false }
    }
}
