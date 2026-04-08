import SwiftUI

struct DeeplinkRowView: View {
    let entry: DeeplinkEntry

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
            // Line 1: scheme://host + path
            HStack(spacing: 0) {
                Text(entry.schemeAndHost)
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.deeplinks)

                Text(entry.path)
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .lineLimit(1)

            // Line 2: params badge + segments count + relative timestamp
            HStack(spacing: InspectorTheme.Spacing.sm) {
                if !entry.queryParameters.isEmpty {
                    let count = entry.queryParameters.count
                    Text("\(count) param\(count == 1 ? "" : "s")")
                        .font(InspectorTheme.Typography.detail)
                        .padding(.horizontal, InspectorTheme.Spacing.pip)
                        .padding(.vertical, InspectorTheme.Spacing.xxs)
                        .background(InspectorTheme.Colors.deeplinks.opacity(InspectorTheme.Opacity.badge))
                        .foregroundStyle(InspectorTheme.Colors.deeplinks)
                        .clipShape(.capsule)
                }

                if !entry.pathComponents.isEmpty {
                    let count = entry.pathComponents.count
                    Text("\(count) segment\(count == 1 ? "" : "s")")
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }

                Spacer()

                Text(entry.timestamp.relativeTimestamp)
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
        }
        .padding(.vertical, InspectorTheme.Spacing.xs)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Deeplink Rows") {
    List {
        DeeplinkRowView(entry: .mockCustomScheme)
            .listRowBackground(InspectorTheme.Colors.surface)
        DeeplinkRowView(entry: .mockUniversalLink)
            .listRowBackground(InspectorTheme.Colors.surface)
        DeeplinkRowView(entry: .mockWidgetLink)
            .listRowBackground(InspectorTheme.Colors.surface)
    }
    .listStyle(.insetGrouped)
    .scrollContentBackground(.hidden)
    .inspectorBackground()
}
#endif
