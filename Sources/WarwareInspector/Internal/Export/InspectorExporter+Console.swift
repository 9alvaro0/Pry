import Foundation

extension InspectorExporter {

    static func generateConsoleSection(_ entries: [LogEntry]) -> String {
        guard !entries.isEmpty else { return "" }

        var md = "---\n\n## Console Logs\n\n"

        let typeCounts = Dictionary(grouping: entries, by: { $0.type })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        let typeList = typeCounts.map { "\($0.value) \($0.key.rawValue)" }
        md += "**\(entries.count)** logs (\(typeList.joined(separator: ", ")))\n\n"

        let sortedEntries = entries.sorted { $0.timestamp > $1.timestamp }

        md += "| Timestamp | Type | Message | Location |\n"
        md += "|-----------|------|---------|----------|\n"

        for entry in sortedEntries {
            let type = entry.type == .error ? "**ERROR**" : entry.type.rawValue
            let message = entry.message
                .replacingOccurrences(of: "|", with: "\\|")
                .replacingOccurrences(of: "\n", with: " ")
            let truncated = message.count > 80 ? String(message.prefix(80)) + "..." : message
            md += "| \(entry.timestamp.formattedTimestamp) | \(type) | \(truncated) | \(entry.location ?? "-") |\n"
        }

        md += "\n"
        return md
    }
}
