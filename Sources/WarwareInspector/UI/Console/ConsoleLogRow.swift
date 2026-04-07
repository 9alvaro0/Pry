import SwiftUI

struct ConsoleLogRowView: View {
    let log: LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: InspectorTheme.Spacing.sm) {
            Image(systemName: log.type.systemImage)
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(log.type.color)
                .frame(width: InspectorTheme.Size.iconSmall)

            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                Text(log.message)
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(log.type.color)
                    .textSelection(.enabled)

                HStack(spacing: InspectorTheme.Spacing.sm) {
                    Text(log.timestamp.formatted(date: .omitted, time: .standard))
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textSecondary)

                    if let location = log.location {
                        Text(location)
                            .font(InspectorTheme.Typography.detail)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, InspectorTheme.Spacing.xs)
        .padding(.horizontal, InspectorTheme.Spacing.sm)
        .background(log.type == .error ? InspectorTheme.Colors.error.opacity(0.05) : Color.clear)
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))
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
}
#endif
