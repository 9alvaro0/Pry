import SwiftUI

struct NetworkRequestRowView: View {
    let entry: NetworkEntry
    var isPinned: Bool = false

    private var isPending: Bool {
        entry.responseStatusCode == nil && entry.responseError == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                // Line 1: Method pill + Path + badges + pin
                HStack(alignment: .center, spacing: PryTheme.Spacing.sm) {
                    methodBadge

                    Text(entry.displayPath)
                        .font(PryTheme.Typography.code)
                        .fontWeight(.medium)
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    if entry.isReplay {
                        tagBadge("REPLAY", color: PryTheme.Colors.accent)
                    }

                    if entry.isMocked {
                        tagBadge("MOCK", color: PryTheme.Colors.syntaxBool)
                    }

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
                }

                // Line 2: Status badge + Host + Size + Duration + Timestamp
                HStack(spacing: PryTheme.Spacing.sm) {
                    if let statusCode = entry.responseStatusCode {
                        Text("\(statusCode)")
                            .pryStatusBadge(statusCode)
                    } else if isPending {
                        statusLabel("PENDING", color: PryTheme.Colors.pending)
                    } else if entry.responseError != nil {
                        statusLabel("ERR", color: PryTheme.Colors.error)
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

                    if let duration = entry.duration {
                        Text(duration.formattedDuration)
                            .font(PryTheme.Typography.codeSmall)
                            .foregroundStyle(PryTheme.Colors.textTertiary)
                    }

                    Text(entry.timestamp.relativeTimestamp)
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }
            }
        .padding(.vertical, PryTheme.Spacing.sm)
    }

    // MARK: - Components

    private var methodBadge: some View {
        Group {
            if let gql = entry.graphQLInfo {
                Text(gql.operationType.rawValue.prefix(3).uppercased())
                    .font(PryTheme.Typography.codeSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(gql.operationType.color)
                    .padding(.horizontal, PryTheme.Spacing.pip)
                    .padding(.vertical, PryTheme.Spacing.xxs)
                    .background(gql.operationType.color.opacity(PryTheme.Opacity.badge))
                    .clipShape(.capsule)
            } else {
                Text(entry.requestMethod)
                    .font(PryTheme.Typography.codeSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(PryTheme.Colors.methodColor(entry.requestMethod))
                    .padding(.horizontal, PryTheme.Spacing.pip)
                    .padding(.vertical, PryTheme.Spacing.xxs)
                    .background(PryTheme.Colors.methodColor(entry.requestMethod).opacity(PryTheme.Opacity.badge))
                    .clipShape(.capsule)
            }
        }
    }

    private func tagBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(PryTheme.Typography.codeSmall)
            .fontWeight(.bold)
            .foregroundStyle(color)
    }

    private func statusLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(PryTheme.Typography.codeSmall)
            .fontWeight(.medium)
            .padding(.horizontal, PryTheme.Spacing.pip)
            .padding(.vertical, PryTheme.Spacing.xxs)
            .background(color.opacity(PryTheme.Opacity.badge))
            .foregroundStyle(color)
            .clipShape(.capsule)
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
