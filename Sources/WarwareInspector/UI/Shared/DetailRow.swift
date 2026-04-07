import SwiftUI

struct DetailRowView: View {
    let label: String
    var value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)
            Spacer(minLength: InspectorTheme.Spacing.sm)
            Text(value)
                .font(InspectorTheme.Typography.body)
                .textSelection(.enabled)
                .multilineTextAlignment(.trailing)
        }
    }
}
