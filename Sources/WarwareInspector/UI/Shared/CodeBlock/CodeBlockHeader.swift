import SwiftUI

struct CodeBlockHeaderView: View {
    let language: ContentLanguage?
    let text: String
    let showExpandButton: Bool
    @Binding var isExpanded: Bool

    var body: some View {
        HStack {
            if let language, language.showsLanguageLabel {
                Text(language.uppercased)
                    .font(InspectorTheme.Typography.detail)
                    .fontWeight(.medium)
                    .foregroundStyle(InspectorTheme.Colors.textSecondary)
            }

            Spacer()

            HStack(spacing: InspectorTheme.Spacing.md) {
                if showExpandButton {
                    Button {
                        withAnimation { isExpanded.toggle() }
                    } label: {
                        HStack(spacing: InspectorTheme.Spacing.xs) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(InspectorTheme.Typography.detail)
                            Text(isExpanded ? "Collapse" : "Expand")
                                .font(InspectorTheme.Typography.detail)
                        }
                        .foregroundStyle(InspectorTheme.Colors.accent)
                    }
                }
                CopyButtonView(valueToCopy: text)
            }
        }
    }
}
