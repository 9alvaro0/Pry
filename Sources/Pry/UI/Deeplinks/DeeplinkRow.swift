import SwiftUI

struct DeeplinkRowView: View {
    let entry: DeeplinkEntry

    var body: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            // Line 1: scheme://host + path
            HStack(spacing: 0) {
                Text(entry.schemeAndHost)
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.accent)

                Text(entry.path)
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .lineLimit(1)

            // Line 2: params badge + segments count + relative timestamp
            HStack(spacing: PryTheme.Spacing.sm) {
                if !entry.queryParameters.isEmpty {
                    let count = entry.queryParameters.count
                    Text("\(count) param\(count == 1 ? "" : "s")")
                        .font(PryTheme.Typography.detail)
                        .padding(.horizontal, PryTheme.Spacing.pip)
                        .padding(.vertical, PryTheme.Spacing.xxs)
                        .background(PryTheme.Colors.accent.opacity(PryTheme.Opacity.badge))
                        .foregroundStyle(PryTheme.Colors.accent)
                        .clipShape(.capsule)
                }

                if !entry.pathComponents.isEmpty {
                    let count = entry.pathComponents.count
                    Text("\(count) segment\(count == 1 ? "" : "s")")
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }

                Spacer()

                Text(entry.timestamp.relativeTimestamp)
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }
        }
        .padding(.vertical, PryTheme.Spacing.xs)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Deeplink Rows") {
    List {
        DeeplinkRowView(entry: .mockCustomScheme)
            .listRowBackground(PryTheme.Colors.surface)
        DeeplinkRowView(entry: .mockUniversalLink)
            .listRowBackground(PryTheme.Colors.surface)
        DeeplinkRowView(entry: .mockWidgetLink)
            .listRowBackground(PryTheme.Colors.surface)
    }
    .listStyle(.insetGrouped)
    .scrollContentBackground(.hidden)
    .pryBackground()
}
#endif
