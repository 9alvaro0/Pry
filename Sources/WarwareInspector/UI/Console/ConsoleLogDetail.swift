import SwiftUI

struct ConsoleLogDetailView: View {
    let log: LogEntry

    @State private var showCopied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header: type + timestamp
                HStack(spacing: InspectorTheme.Spacing.sm) {
                    Image(systemName: log.type.systemImage)
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(log.type.color)

                    Text(log.type.rawValue.uppercased())
                        .font(InspectorTheme.Typography.detail)
                        .fontWeight(.semibold)
                        .foregroundStyle(log.type.color)

                    Spacer()

                    Text(log.timestamp.formatFullTimestamp())
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }
                .padding(.vertical, InspectorTheme.Spacing.lg)

                Divider().overlay(InspectorTheme.Colors.border)

                // Message
                DetailSectionView(title: "Message") {
                    Text(log.message)
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.textPrimary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(InspectorTheme.Spacing.md)
                        .background(InspectorTheme.Colors.surface)
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                }

                // Source
                if log.file != nil || log.function != nil {
                    DetailSectionView(title: "Source") {
                        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                            if let file = log.file {
                                DetailRowView(label: "File", value: file)
                            }
                            if let function = log.function {
                                DetailRowView(label: "Function", value: function)
                            }
                            if let line = log.line {
                                DetailRowView(label: "Line", value: "\(line)")
                            }
                            if let location = log.location {
                                DetailRowView(label: "Location", value: location)
                            }
                        }
                    }
                }

                // Additional info
                if let info = log.additionalInfo, !info.isEmpty {
                    DetailSectionView(title: "Additional Info") {
                        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                            ForEach(Array(info.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                                DetailRowView(label: key, value: value)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, InspectorTheme.Spacing.lg)
        }
        .inspectorBackground()
        .navigationTitle("Log Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    copyLog()
                } label: {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(showCopied ? InspectorTheme.Colors.success : InspectorTheme.Colors.textSecondary)
                }
            }
        }
    }

    private func copyLog() {
        var text = "[\(log.type.rawValue.uppercased())] \(log.message)"
        if let location = log.location {
            text += "\n\(location)"
        }
        text += "\n\(log.timestamp.formatFullTimestamp())"
        UIPasteboard.general.string = text
        showCopied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            showCopied = false
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Detail - Info") {
    NavigationStack {
        ConsoleLogDetailView(log: .mockInfo)
    }
}

#Preview("Detail - Error") {
    NavigationStack {
        ConsoleLogDetailView(log: .mockError)
    }
}

#Preview("Detail - Debug") {
    NavigationStack {
        ConsoleLogDetailView(log: .mockDebug)
    }
}
#endif
