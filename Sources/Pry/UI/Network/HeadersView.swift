import SwiftUI

/// Displays HTTP headers with toggle between table and raw text view.
struct HeadersView: View {
    let headers: [String: String]
    let title: String

    @State private var showRaw = false

    var body: some View {
        DetailSectionView(title: title, collapsible: true, startCollapsed: true) {
            VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                // Raw toggle
                HStack {
                    Spacer()
                    Button {
                        showRaw.toggle()
                    } label: {
                        Text(showRaw ? "Table" : "Raw")
                            .font(PryTheme.Typography.detail)
                            .foregroundStyle(PryTheme.Colors.accent)
                    }
                }

                if showRaw {
                    rawView
                } else {
                    tableView
                }
            }
        }
    }

    private var tableView: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            ForEach(Array(headers.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                if key == "Authorization", value.count > 50 {
                    HStack(alignment: .top) {
                        Text(key)
                            .font(PryTheme.Typography.body)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
                        Spacer(minLength: PryTheme.Spacing.sm)
                        Text(String(value.prefix(30)) + "...")
                            .font(PryTheme.Typography.body)
                            .multilineTextAlignment(.trailing)
                        CopyButtonView(valueToCopy: value)
                    }
                } else {
                    DetailRowView(label: key, value: value)
                }
            }
        }
    }

    private var rawView: some View {
        let raw = headers.sorted(by: { $0.key < $1.key })
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")

        return Text(raw)
            .font(PryTheme.Typography.code)
            .foregroundStyle(PryTheme.Colors.textPrimary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PryTheme.Spacing.sm)
            .background(PryTheme.Colors.background)
            .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))
    }
}
