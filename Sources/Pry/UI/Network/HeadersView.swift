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
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(headers.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                VStack(alignment: .leading, spacing: PryTheme.Spacing.xxs) {
                    Text(key)
                        .font(PryTheme.Typography.codeSmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(PryTheme.Colors.textSecondary)

                    Text(value)
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                        .textSelection(.enabled)
                }
                .padding(.vertical, PryTheme.Spacing.sm)

                if key != headers.keys.sorted().last {
                    Divider().overlay(PryTheme.Colors.border)
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
