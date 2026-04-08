import SwiftUI

struct ConsoleLogRowView: View {
    let log: LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: PryTheme.Spacing.sm) {
            // Type icon
            Image(systemName: log.type.systemImage)
                .font(PryTheme.Typography.detail)
                .foregroundStyle(log.type.color)
                .frame(width: PryTheme.Size.iconSmall)
                .padding(.top, PryTheme.Spacing.xxs)

            VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                // Message
                Text(log.message)
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textPrimary)
                    .textSelection(.enabled)

                // Metadata: relative time + location
                HStack(spacing: PryTheme.Spacing.sm) {
                    Text(log.timestamp.relativeTimestamp)
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.textTertiary)

                    if let location = log.location {
                        Text(location)
                            .font(PryTheme.Typography.detail)
                            .foregroundStyle(PryTheme.Colors.textTertiary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, PryTheme.Spacing.xs)
        .overlay(alignment: .leading) {
            // Left accent bar for errors/warnings
            if log.type == .error || log.type == .warning {
                RoundedRectangle(cornerRadius: 2)
                    .fill(log.type.color)
                    .frame(width: 3)
                    .padding(.vertical, PryTheme.Spacing.xs)
                    .offset(x: -PryTheme.Spacing.md)
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
    .pryBackground()
}
#endif
