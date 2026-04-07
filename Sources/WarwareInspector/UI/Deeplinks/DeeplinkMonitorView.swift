import SwiftUI

struct DeeplinkMonitorView: View {
    @Bindable var store: InspectorStore

    @State private var searchText: String = ""

    private var filteredEntries: [DeeplinkEntry] {
        guard !searchText.isEmpty else { return store.deeplinkEntries }

        return store.deeplinkEntries.filter { entry in
            entry.url.localizedCaseInsensitiveContains(searchText) ||
            entry.queryParameters.contains { param in
                param.name.localizedCaseInsensitiveContains(searchText) ||
                (param.value?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    var body: some View {
        Group {
            if store.deeplinkEntries.isEmpty {
                EmptyStateView(
                    title: "No deeplinks received",
                    systemImage: "link",
                    description: "Deeplinks and universal links will appear here as the app receives them"
                )
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        NavigationLink(destination: DeeplinkDetailView(entry: entry)) {
                            DeeplinkRowView(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .searchable(text: $searchText, prompt: "Search deeplinks...")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Deeplinks - With Data") {
    NavigationStack {
        DeeplinkMonitorView(store: .deeplinksOnly)
            .navigationTitle("Deeplinks")
    }
}

#Preview("Deeplinks - Empty") {
    NavigationStack {
        DeeplinkMonitorView(store: InspectorStore())
            .navigationTitle("Deeplinks")
    }
}
#endif
