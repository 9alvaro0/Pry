import SwiftUI

struct JSONHeaderView: View {
    let jsonText: String

    var body: some View {
        HStack {
            Text("JSON")
                .font(InspectorTheme.Typography.detail)
                .fontWeight(.medium)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)
            Spacer()
            CopyButtonView(valueToCopy: jsonText)
        }
    }
}
