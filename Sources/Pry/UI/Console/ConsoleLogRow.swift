import SwiftUI

struct ConsoleLogRowView: View {
    let log: LogEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: PryTheme.Spacing.sm) {
            Text(log.timestamp.consoleTimestamp)
                .font(PryTheme.Typography.codeSmall)
                .foregroundStyle(PryTheme.Colors.textTertiary)
                .monospacedDigit()

            Text(log.type.shortLabel)
                .font(PryTheme.Typography.codeSmall)
                .fontWeight(.bold)
                .foregroundStyle(log.type.color)
                .frame(width: 28, alignment: .leading)

            Text(log.message)
                .font(PryTheme.Typography.code)
                .foregroundStyle(log.type == .error ? PryTheme.Colors.error : PryTheme.Colors.textPrimary)
                .lineLimit(3)
        }
        .frame(minHeight: 44)
    }
}

// MARK: - LogType Extension

extension LogType {
    var shortLabel: String {
        switch self {
        case .error: "ERR"
        case .warning: "WRN"
        case .info: "INF"
        case .success: "OK"
        case .debug: "DBG"
        case .network: "NET"
        }
    }
}

// MARK: - Timestamp Extension

extension Date {
    private static let consoleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var consoleTimestamp: String {
        Self.consoleFormatter.string(from: self)
    }
}

#if DEBUG
#Preview("Console Rows") {
    List {
        ConsoleLogRowView(log: .mockInfo)
        ConsoleLogRowView(log: .mockSuccess)
        ConsoleLogRowView(log: .mockWarning)
        ConsoleLogRowView(log: .mockError)
        ConsoleLogRowView(log: .mockDebug)
        ConsoleLogRowView(log: .mockNetwork)
    }
    .listStyle(.plain)
    .pryBackground()
}
#endif
