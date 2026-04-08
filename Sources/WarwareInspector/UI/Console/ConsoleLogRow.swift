import SwiftUI

struct ConsoleLogRowView: View {
    let log: LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: InspectorTheme.Spacing.sm) {
            // Type icon
            Image(systemName: log.type.systemImage)
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(log.type.color)
                .frame(width: InspectorTheme.Size.iconSmall)
                .padding(.top, InspectorTheme.Spacing.xxs)

            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                // Message
                Text(log.message)
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    .textSelection(.enabled)

                // Metadata: relative time + location
                HStack(spacing: InspectorTheme.Spacing.sm) {
                    Text(log.timestamp.relativeTimestamp)
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)

                    if let location = log.location {
                        Text(location)
                            .font(InspectorTheme.Typography.detail)
                            .foregroundStyle(InspectorTheme.Colors.textTertiary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, InspectorTheme.Spacing.xs)
        .overlay(alignment: .leading) {
            // Left accent bar for errors/warnings
            if log.type == .error || log.type == .warning {
                RoundedRectangle(cornerRadius: 2)
                    .fill(log.type.color)
                    .frame(width: 3)
                    .padding(.vertical, InspectorTheme.Spacing.xs)
                    .offset(x: -InspectorTheme.Spacing.md)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Log Types") {
    List {
        ConsoleLogRowView(log: .mockInfo)
        ConsoleLogRowView(log: .mockSuccess)
        ConsoleLogRowView(log: .mockWarning)
        ConsoleLogRowView(log: .mockError)
        ConsoleLogRowView(log: .mockDebug)
        ConsoleLogRowView(log: .mockNetwork)
    }
    .listStyle(.insetGrouped)
    .inspectorBackground()
}
#endif
