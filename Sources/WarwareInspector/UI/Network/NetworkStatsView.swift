import SwiftUI

struct NetworkStatsView: View {
    let entries: [NetworkEntry]

    private var totalRequests: Int { entries.count }

    private var successCount: Int {
        entries.filter { $0.isSuccess }.count
    }

    private var errorCount: Int {
        entries.filter { ($0.responseStatusCode ?? 0) >= 400 || $0.responseError != nil }.count
    }

    private var pendingCount: Int {
        entries.filter { $0.responseStatusCode == nil && $0.responseError == nil }.count
    }

    private var avgDuration: TimeInterval? {
        let durations = entries.compactMap { $0.duration }
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }

    private var totalTransferred: Int {
        entries.compactMap { $0.responseSize }.reduce(0, +)
    }

    private var slowestRequest: NetworkEntry? {
        entries.max(by: { ($0.duration ?? 0) < ($1.duration ?? 0) })
    }

    private var errorGroups: [ErrorGroup] {
        let errors = entries.filter { ($0.responseStatusCode ?? 0) >= 400 || $0.responseError != nil }
        var groups: [String: ErrorGroup] = [:]

        for entry in errors {
            let path = entry.requestURL.extractPath()
            let key = "\(entry.requestMethod) \(path) \(entry.responseStatusCode ?? 0)"
            if groups[key] != nil {
                groups[key]!.count += 1
            } else {
                groups[key] = ErrorGroup(
                    key: key,
                    method: entry.requestMethod,
                    path: path,
                    statusCode: entry.responseStatusCode,
                    count: 1
                )
            }
        }

        return groups.values.sorted { $0.count > $1.count }
    }

    private var topHosts: [(host: String, count: Int)] {
        var counts: [String: Int] = [:]
        for entry in entries {
            counts[entry.requestURL.extractHost(), default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.prefix(3).map { (host: $0.key, count: $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.md) {
            // Row 1: Request counts
            HStack(spacing: InspectorTheme.Spacing.sm) {
                statCard(value: "\(totalRequests)", label: "Total", color: InspectorTheme.Colors.textPrimary)
                statCard(value: "\(successCount)", label: "Success", color: InspectorTheme.Colors.success)
                statCard(value: "\(errorCount)", label: "Errors", color: InspectorTheme.Colors.error)
                if pendingCount > 0 {
                    statCard(value: "\(pendingCount)", label: "Pending", color: InspectorTheme.Colors.pending)
                }
            }

            // Error grouping
            if !errorGroups.isEmpty {
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                    ForEach(errorGroups.prefix(3), id: \.key) { group in
                        HStack(spacing: InspectorTheme.Spacing.sm) {
                            Text("\(group.count)x")
                                .font(InspectorTheme.Typography.code)
                                .fontWeight(.bold)
                                .foregroundStyle(InspectorTheme.Colors.error)
                                .frame(width: 32, alignment: .trailing)

                            Text("\(group.method) \(group.path)")
                                .font(InspectorTheme.Typography.code)
                                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            if let status = group.statusCode {
                                Text("\(status)")
                                    .font(InspectorTheme.Typography.codeSmall)
                                    .foregroundStyle(InspectorTheme.Colors.error)
                            }
                        }
                        .padding(.horizontal, InspectorTheme.Spacing.sm)
                        .padding(.vertical, InspectorTheme.Spacing.xs)
                        .background(InspectorTheme.Colors.error.opacity(InspectorTheme.Opacity.faint))
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))
                    }
                }
            }

            // Row 2: Performance
            HStack(spacing: InspectorTheme.Spacing.sm) {
                if let avg = avgDuration {
                    statCard(
                        value: String(format: "%.0fms", avg * 1000),
                        label: "Avg Time",
                        color: InspectorTheme.Colors.accent
                    )
                }
                statCard(
                    value: totalTransferred.formatBytes(),
                    label: "Transferred",
                    color: InspectorTheme.Colors.accent
                )
                if let slowest = slowestRequest, let dur = slowest.duration {
                    statCard(
                        value: String(format: "%.0fms", dur * 1000),
                        label: "Slowest",
                        color: dur > 1.0 ? InspectorTheme.Colors.error : InspectorTheme.Colors.warning
                    )
                }
            }
        }
        .padding(.vertical, InspectorTheme.Spacing.xs)
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: InspectorTheme.Spacing.xxs) {
            Text(value)
                .font(InspectorTheme.Typography.code)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, InspectorTheme.Spacing.sm)
        .background(InspectorTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
    }
}

// MARK: - Error Group Model

private struct ErrorGroup {
    let key: String
    let method: String
    let path: String
    let statusCode: Int?
    var count: Int
}

// MARK: - Previews

#if DEBUG
#Preview("Stats - With Data") {
    VStack {
        NetworkStatsView(entries: InspectorStore.networkOnly.networkEntries)
        Spacer()
    }
    .inspectorBackground()
}

#Preview("Stats - Empty") {
    VStack {
        NetworkStatsView(entries: [])
        Spacer()
    }
    .inspectorBackground()
}
#endif
