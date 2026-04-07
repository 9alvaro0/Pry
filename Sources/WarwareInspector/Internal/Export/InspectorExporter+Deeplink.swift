import Foundation

extension InspectorExporter {

    static func generateDeeplinkSection(_ entries: [DeeplinkEntry]) -> String {
        guard !entries.isEmpty else { return "" }

        var md = "---\n\n## Deeplinks\n\n"
        md += "**\(entries.count)** deeplinks received\n\n"

        let sortedEntries = entries.sorted { $0.timestamp > $1.timestamp }

        md += "| Timestamp | URL | Params |\n"
        md += "|-----------|-----|--------|\n"

        for entry in sortedEntries {
            let paramsCount = entry.queryParameters.isEmpty ? "-" : "\(entry.queryParameters.count)"
            md += "| \(entry.timestamp.formattedTimestamp) | `\(entry.url.sanitizedURL())` | \(paramsCount) |\n"
        }

        md += "\n"

        let entriesWithParams = sortedEntries.filter { !$0.queryParameters.isEmpty }
        if !entriesWithParams.isEmpty {
            md += "<details>\n<summary>Query parameters (\(entriesWithParams.count) deeplinks)</summary>\n\n"
            for entry in entriesWithParams {
                let scheme = entry.scheme ?? ""
                let host = entry.host ?? ""
                md += "**\(scheme)://\(host)\(entry.path)**\n\n"
                md += "| Parameter | Value |\n"
                md += "|-----------|-------|\n"
                for param in entry.queryParameters {
                    md += "| \(param.name) | `\(param.value ?? "nil")` |\n"
                }
                md += "\n"
            }
            md += "</details>\n\n"
        }

        return md
    }
}
