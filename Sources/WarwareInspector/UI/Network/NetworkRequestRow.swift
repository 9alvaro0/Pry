import SwiftUI

struct NetworkRequestRowView: View {
    let entry: NetworkEntry

    private var isPending: Bool {
        entry.responseStatusCode == nil && entry.responseError == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
            // Line 1: Method + Path + Duration
            HStack(alignment: .center, spacing: InspectorTheme.Spacing.sm) {
                Text(entry.requestMethod)
                    .font(InspectorTheme.Typography.code)
                    .fontWeight(.semibold)
                    .foregroundStyle(InspectorTheme.Colors.textSecondary)
                    .frame(width: 52, alignment: .leading)

                Text(entry.requestURL.extractPath())
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                if let duration = entry.duration {
                    Text(Optional(duration).formattedDuration)
                        .font(InspectorTheme.Typography.codeSmall)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }
            }

            // Line 2: Status badge + Host + Timestamp
            HStack(spacing: InspectorTheme.Spacing.sm) {
                if let statusCode = entry.responseStatusCode {
                    Text("\(statusCode)")
                        .inspectorStatusBadge(statusCode)
                } else if isPending {
                    Text("PENDING")
                        .font(InspectorTheme.Typography.codeSmall)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, InspectorTheme.Spacing.xxs)
                        .background(InspectorTheme.Colors.pending.opacity(0.15))
                        .foregroundStyle(InspectorTheme.Colors.pending)
                        .clipShape(.capsule)
                } else if entry.responseError != nil {
                    Text("ERR")
                        .font(InspectorTheme.Typography.codeSmall)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, InspectorTheme.Spacing.xxs)
                        .background(InspectorTheme.Colors.error.opacity(0.15))
                        .foregroundStyle(InspectorTheme.Colors.error)
                        .clipShape(.capsule)
                }

                Text(entry.requestURL.extractHost())
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
                    .lineLimit(1)

                Spacer()

                if let size = entry.responseSize, size > 0 {
                    Text(size.formatBytes())
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }

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
#Preview("Row States") {
    List {
        NetworkRequestRowView(entry: .mockSuccess)
        NetworkRequestRowView(entry: .mockError)
        NetworkRequestRowView(entry: .mockServerError)
        NetworkRequestRowView(entry: .mockPending)
        NetworkRequestRowView(entry: .mockDelete)
        NetworkRequestRowView(entry: .mockPatch)
        NetworkRequestRowView(entry: .mockNoAuth)
    }
    .listStyle(.insetGrouped)
    .inspectorBackground()
}
#endif
