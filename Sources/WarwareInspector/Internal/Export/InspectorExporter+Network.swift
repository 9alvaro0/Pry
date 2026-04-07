import Foundation

extension InspectorExporter {

    static func generateNetworkSection(_ entries: [NetworkEntry]) -> String {
        guard !entries.isEmpty else { return "" }

        var md = "---\n\n## Network\n\n"

        // Summary
        let successCount = entries.filter { ($0.responseStatusCode ?? 0) >= 200 && ($0.responseStatusCode ?? 0) < 300 }.count
        let errorCount = entries.filter { ($0.responseStatusCode ?? 0) >= 400 }.count
        let avgDuration = entries.compactMap { $0.duration }.reduce(0, +) / Double(max(1, entries.count))

        md += "**\(entries.count)** requests · **\(successCount)** ok · **\(errorCount)** errors · avg **\(String(format: "%.0f", avgDuration * 1000))ms**\n\n"

        // Errors table
        let errorEntries = entries
            .filter { ($0.responseStatusCode ?? 0) >= 400 || $0.responseError != nil }
            .sorted { $0.timestamp > $1.timestamp }

        if !errorEntries.isEmpty {
            md += "### Errors (\(errorEntries.count))\n\n"
            md += "| Timestamp | Method | Path | Status | Duration | Error |\n"
            md += "|-----------|--------|------|--------|----------|-------|\n"

            for entry in errorEntries {
                let error = entry.displayError?.sanitizedError() ?? "-"
                let truncatedError = error.count > 60 ? String(error.prefix(60)) + "..." : error
                md += "| \(entry.timestamp.formattedTimestamp) | `\(entry.requestMethod)` | \(entry.requestURL.extractPath()) | `\(entry.responseStatusCode ?? 0)` | \(entry.duration.formattedDuration) | \(truncatedError) |\n"
            }
            md += "\n"

            let errorsWithBody = errorEntries.filter { $0.responseBody != nil && !$0.responseBody!.isEmpty }
            if !errorsWithBody.isEmpty {
                md += "<details>\n<summary>Error response bodies (\(errorsWithBody.count))</summary>\n\n"
                for entry in errorsWithBody {
                    md += "**`\(entry.requestMethod)` \(entry.requestURL.extractPath()) — `\(entry.responseStatusCode ?? 0)`**\n\n"
                    md += "```json\n\(entry.responseBody!)\n```\n\n"
                }
                md += "</details>\n\n"
            }
        }

        // All requests
        let sortedEntries = entries.sorted { $0.timestamp > $1.timestamp }

        md += "### All Requests (\(entries.count))\n\n"
        md += "| Timestamp | Method | Path | Status | Duration |\n"
        md += "|-----------|--------|------|--------|----------|\n"

        for entry in sortedEntries {
            let status = entry.responseStatusCode.map { "`\($0)`" } ?? "`-`"
            md += "| \(entry.timestamp.formattedTimestamp) | `\(entry.requestMethod)` | \(entry.requestURL.extractPath()) | \(status) | \(entry.duration.formattedDuration) |\n"
        }

        md += "\n"
        return md
    }
}
