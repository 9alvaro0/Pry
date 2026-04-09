import SwiftUI

@_spi(PryPro) public struct DetailRowView: View {
    @_spi(PryPro) public let label: String
    @_spi(PryPro) public var value: String

    @_spi(PryPro) public var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(PryTheme.Typography.body)
                .foregroundStyle(PryTheme.Colors.textSecondary)
            Spacer(minLength: PryTheme.Spacing.sm)
            Text(value)
                .font(PryTheme.Typography.body)
                .textSelection(.enabled)
                .multilineTextAlignment(.trailing)
        }
    }
}

#if DEBUG
#Preview("Detail Rows") {
    VStack(spacing: PryTheme.Spacing.sm) {
        DetailRowView(label: "Host", value: "api.example.com")
        DetailRowView(label: "Path", value: "/v1/users")
        DetailRowView(label: "Status", value: "200 OK")
        DetailRowView(label: "Long Value", value: "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.very.long.token")
    }
    .padding()
    .pryBackground()
}
#endif
