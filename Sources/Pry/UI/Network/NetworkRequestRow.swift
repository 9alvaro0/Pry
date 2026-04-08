import SwiftUI

struct NetworkRequestRowView: View {
    let entry: NetworkEntry
    var isPinned: Bool = false

    private var isPending: Bool {
        entry.responseStatusCode == nil && entry.responseError == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
            // Line 1: Method + Path + Pin + Duration
            HStack(alignment: .center, spacing: PryTheme.Spacing.sm) {
                // Method — for GraphQL show operation type badge instead
                if let gql = entry.graphQLInfo {
                    Text(gql.operationType.rawValue.prefix(3).uppercased())
                        .font(PryTheme.Typography.codeSmall)
                        .fontWeight(.bold)
                        .foregroundStyle(gql.operationType.color)
                        .frame(width: PryTheme.Size.methodColumn, alignment: .leading)
                } else {
                    Text(entry.requestMethod)
                        .font(PryTheme.Typography.code)
                        .fontWeight(.semibold)
                        .foregroundStyle(PryTheme.Colors.textSecondary)
                        .frame(width: PryTheme.Size.methodColumn, alignment: .leading)
                }

                // Path — for GraphQL show operation name
                Text(entry.displayPath)
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                if entry.isReplay {
                    Text("REPLAY")
                        .font(PryTheme.Typography.codeSmall)
                        .fontWeight(.bold)
                        .foregroundStyle(PryTheme.Colors.accent)
                }

                if entry.isMocked {
                    Text("MOCK")
                        .font(PryTheme.Typography.codeSmall)
                        .fontWeight(.bold)
                        .foregroundStyle(PryTheme.Colors.syntaxBool)
                }

                // GraphQL errors indicator
                if let gql = entry.graphQLInfo, gql.hasErrors {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(PryTheme.Typography.smallIcon)
                        .foregroundStyle(PryTheme.Colors.error)
                }

                if isPinned {
                    Image(systemName: "pin.fill")
                        .font(PryTheme.Typography.smallIcon)
                        .foregroundStyle(PryTheme.Colors.warning)
                }

                if let duration = entry.duration {
                    Text(duration.formattedDuration)
                        .font(PryTheme.Typography.codeSmall)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }
            }

            // Line 2: Status badge + Host + Size + Timestamp
            HStack(spacing: PryTheme.Spacing.sm) {
                if let statusCode = entry.responseStatusCode {
                    Text("\(statusCode)")
                        .pryStatusBadge(statusCode)
                } else if isPending {
                    Text("PENDING")
                        .font(PryTheme.Typography.codeSmall)
                        .fontWeight(.medium)
                        .padding(.horizontal, PryTheme.Spacing.pip)
                        .padding(.vertical, PryTheme.Spacing.xxs)
                        .background(PryTheme.Colors.pending.opacity(PryTheme.Opacity.badge))
                        .foregroundStyle(PryTheme.Colors.pending)
                        .clipShape(.capsule)
                } else if entry.responseError != nil {
                    Text("ERR")
                        .font(PryTheme.Typography.codeSmall)
                        .fontWeight(.medium)
                        .padding(.horizontal, PryTheme.Spacing.pip)
                        .padding(.vertical, PryTheme.Spacing.xxs)
                        .background(PryTheme.Colors.error.opacity(PryTheme.Opacity.badge))
                        .foregroundStyle(PryTheme.Colors.error)
                        .clipShape(.capsule)
                }

                Text(entry.requestURL.extractHost())
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
                    .lineLimit(1)

                Spacer()

                if let size = entry.responseSize, size > 0 {
                    Text(size.formatBytes())
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }

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
#Preview("Row States") {
    List {
        NetworkRequestRowView(entry: .mockSuccess, isPinned: true)
        NetworkRequestRowView(entry: .mockError)
        NetworkRequestRowView(entry: .mockServerError)
        NetworkRequestRowView(entry: .mockPending)
        NetworkRequestRowView(entry: .mockDelete, isPinned: true)
        NetworkRequestRowView(entry: .mockPatch)
        NetworkRequestRowView(entry: .mockNoAuth)
        NetworkRequestRowView(entry: .mockMocked)
        NetworkRequestRowView(entry: .mockReplay)
        NetworkRequestRowView(entry: .mockGraphQLQuery)
        NetworkRequestRowView(entry: .mockGraphQLMutation)
        NetworkRequestRowView(entry: .mockGraphQLError)
    }
    .listStyle(.insetGrouped)
    .pryBackground()
}
#endif
