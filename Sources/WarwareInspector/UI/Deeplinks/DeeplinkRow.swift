import SwiftUI

struct DeeplinkRowView: View {
    let entry: DeeplinkEntry

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
            HStack {
                Image(systemName: "link")
                    .font(InspectorTheme.Typography.body)
                    .foregroundStyle(InspectorTheme.Colors.deeplinks)
                    .frame(width: InspectorTheme.Size.iconSmall)

                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                    HStack {
                        Text(entry.schemeAndHost)
                            .font(InspectorTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(InspectorTheme.Colors.deeplinks)

                        Text(entry.path)
                            .font(InspectorTheme.Typography.body)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()
                    }

                    HStack {
                        if !entry.queryParameters.isEmpty {
                            Text("\(entry.queryParameters.count) params")
                                .font(InspectorTheme.Typography.detail)
                                .padding(.horizontal, 6)
                                .padding(.vertical, InspectorTheme.Spacing.xxs)
                                .background(InspectorTheme.Colors.deeplinks.opacity(0.15))
                                .foregroundStyle(InspectorTheme.Colors.deeplinks)
                                .clipShape(.capsule)
                        }

                        if !entry.pathComponents.isEmpty {
                            Text("\(entry.pathComponents.count) segments")
                                .font(InspectorTheme.Typography.detail)
                                .foregroundStyle(InspectorTheme.Colors.textSecondary)
                        }

                        Spacer()

                        Text(entry.timestamp.formattedTimestamp)
                            .font(InspectorTheme.Typography.detail)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)
                    }
                }
            }
            .padding(.vertical, InspectorTheme.Spacing.xs)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Deeplink Rows") {
    List {
        DeeplinkRowView(entry: .mockCustomScheme)
        DeeplinkRowView(entry: .mockUniversalLink)
        DeeplinkRowView(entry: .mockWidgetLink)
    }
    .listStyle(.insetGrouped)
}
#endif
