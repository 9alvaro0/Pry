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

#if DEBUG
#Preview("Detail Rows") {
    VStack(spacing: InspectorTheme.Spacing.sm) {
        DetailRowView(label: "Host", value: "api.example.com")
        DetailRowView(label: "Path", value: "/v1/users")
        DetailRowView(label: "Status", value: "200 OK")
        DetailRowView(label: "Long Value", value: "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.very.long.token")
    }
    .padding()
    .inspectorBackground()
}
#endif
