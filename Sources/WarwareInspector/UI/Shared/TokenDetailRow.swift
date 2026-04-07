import SwiftUI

struct TokenDetailRowView: View {
    let label: String
    let preview: String
    let fullToken: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)
            Spacer(minLength: InspectorTheme.Spacing.sm)
            VStack(alignment: .trailing, spacing: InspectorTheme.Spacing.xs) {
                Text(preview)
                    .font(InspectorTheme.Typography.body)
                    .multilineTextAlignment(.trailing)
                CopyButtonView(
                    valueToCopy: fullToken,
                    style: .labeled("Copy Full Token", copiedLabel: "Copied!")
                )
            }
        }
    }
}
