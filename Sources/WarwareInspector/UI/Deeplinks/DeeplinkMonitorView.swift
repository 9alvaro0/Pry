import SwiftUI

struct DeeplinkMonitorView: View {
    @Bindable var store: InspectorStore

    @State private var searchText: String = ""
    @State private var showSimulator = false

    private var filteredEntries: [DeeplinkEntry] {
        guard !searchText.isEmpty else { return store.deeplinkEntries }
        let query = searchText.lowercased()

        return store.deeplinkEntries.filter { entry in
            entry.url.lowercased().contains(query) ||
            (entry.scheme?.lowercased().contains(query) ?? false) ||
            (entry.host?.lowercased().contains(query) ?? false) ||
            entry.queryParameters.contains { param in
                param.name.lowercased().contains(query) ||
                (param.value?.lowercased().contains(query) ?? false)
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
                    Section {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(destination: DeeplinkDetailView(entry: entry)) {
                                DeeplinkRowView(entry: entry)
                            }
                            .listRowBackground(InspectorTheme.Colors.surface)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.removeDeeplinkEntry(entry.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    UIPasteboard.general.string = entry.url
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                .tint(InspectorTheme.Colors.deeplinks)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .contentMargins(.vertical, InspectorTheme.Spacing.sm)
            }
        }
        .inspectorBackground()
        .searchable(text: $searchText, prompt: "URL, scheme, host...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSimulator = true
                } label: {
                    Image(systemName: "play.circle")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(InspectorTheme.Colors.deeplinks)
                }
            }
        }
        .sheet(isPresented: $showSimulator) {
            DeeplinkSimulatorView(store: store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(InspectorTheme.Colors.background)
        }
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

#Preview("Deeplinks - Full") {
    NavigationStack {
        DeeplinkMonitorView(store: .preview)
            .navigationTitle("Deeplinks")
    }
}
#endif
