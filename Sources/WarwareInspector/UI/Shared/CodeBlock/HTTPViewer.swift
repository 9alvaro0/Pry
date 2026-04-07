import SwiftUI

struct HTTPViewerView: View {
    let httpText: String

    private struct ParsedHTTP {
        let method: String
        let path: String
        let httpVersion: String
        let headers: [String: String]
    }

    private var parsedHTTP: ParsedHTTP {
        let lines = httpText.split(whereSeparator: \.isNewline)
        guard let requestLine = lines.first else {
            return ParsedHTTP(method: "", path: "", httpVersion: "", headers: [:])
        }

        let parts = requestLine.split(separator: " ")
        let method = parts.first.map(String.init) ?? ""
        let path = parts.dropFirst().first.map(String.init) ?? ""
        let httpVersion = parts.dropFirst(2).first.map(String.init) ?? "HTTP/1.1"

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  let separatorIndex = trimmed.firstIndex(of: ":") else { continue }
            let key = trimmed[..<separatorIndex]
            let valueStart = trimmed.index(after: separatorIndex)
            let value = trimmed[valueStart...].trimmingCharacters(in: .whitespaces)
            headers[String(key)] = value
        }

        return ParsedHTTP(method: method, path: path, httpVersion: httpVersion, headers: headers)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
            HStack(spacing: InspectorTheme.Spacing.sm) {
                Text(parsedHTTP.method)
                    .font(InspectorTheme.Typography.code)
                    .fontWeight(.bold)
                    .foregroundStyle(InspectorTheme.Colors.accent)
                    .padding(.horizontal, InspectorTheme.Spacing.sm)
                    .padding(.vertical, InspectorTheme.Spacing.xxs)
                    .background(InspectorTheme.Colors.accent.opacity(0.1))
                    .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))

                Text(parsedHTTP.path)
                    .font(InspectorTheme.Typography.code)

                Spacer()

                Text(parsedHTTP.httpVersion)
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textSecondary)
            }

            if !parsedHTTP.headers.isEmpty {
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                    ForEach(Array(parsedHTTP.headers.keys.sorted()), id: \.self) { key in
                        HStack(alignment: .top, spacing: InspectorTheme.Spacing.xs) {
                            Text("\(key):")
                                .font(InspectorTheme.Typography.code)
                                .fontWeight(.medium)
                                .foregroundStyle(InspectorTheme.Colors.warning)
                                .frame(minWidth: 80, alignment: .leading)
                            Text(parsedHTTP.headers[key] ?? "")
                                .font(InspectorTheme.Typography.code)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
        .inspectorCodeBlock()
    }
}
