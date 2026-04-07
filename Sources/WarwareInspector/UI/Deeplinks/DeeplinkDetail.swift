import SwiftUI

struct DeeplinkDetailView: View {
    let entry: DeeplinkEntry

    var body: some View {
        List {
            Section {
                Text(entry.url)
                    .font(InspectorTheme.Typography.code)
                    .textSelection(.enabled)
                    .listRowInsets(EdgeInsets(top: InspectorTheme.Spacing.md, leading: InspectorTheme.Spacing.lg, bottom: InspectorTheme.Spacing.md, trailing: InspectorTheme.Spacing.lg))
            } header: {
                Text("Full URL")
            }

            Section {
                if let scheme = entry.scheme {
                    DetailRowView(label: "Scheme", value: scheme)
                }
                if let host = entry.host {
                    DetailRowView(label: "Host", value: host)
                }
                DetailRowView(label: "Path", value: entry.path)
                if let fragment = entry.fragment {
                    DetailRowView(label: "Fragment", value: fragment)
                }
            } header: {
                Text("URL Components")
            }

            if !entry.pathComponents.isEmpty {
                Section {
                    ForEach(Array(entry.pathComponents.enumerated()), id: \.offset) { index, component in
                        DetailRowView(label: "[\(index)]", value: component)
                    }
                } header: {
                    Text("Path Components")
                }
            }

            if !entry.queryParameters.isEmpty {
                Section {
                    ForEach(entry.queryParameters) { param in
                        DetailRowView(label: param.name, value: param.value ?? "nil")
                    }
                } header: {
                    Text("Query Parameters (\(entry.queryParameters.count))")
                }
            }

            Section {
                DetailRowView(
                    label: "Timestamp",
                    value: entry.timestamp.formatted(date: .abbreviated, time: .standard)
                )
            } header: {
                Text("Metadata")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Deeplink Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = entry.url
                } label: {
                    Image(systemName: "doc.on.doc")
                }
            }
        }
    }
}
