import SwiftUI

struct DeeplinkMonitorView: View {
    @Bindable var store: PryStore

    @Environment(\.openURL) private var openURL
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
                ContentUnavailableView {
                    Label("No deeplinks received", systemImage: "link")
                } description: {
                    Text("Deeplinks will appear here as the app receives them")
                } actions: {
                    Button {
                        showSimulator = true
                    } label: {
                        Label("Simulate Deeplink", systemImage: "play.fill")
                            .font(PryTheme.Typography.body)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(PryTheme.Colors.deeplinks)
                }
            } else {
                List {
                    Section {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(destination: DeeplinkDetailView(entry: entry)) {
                                DeeplinkRowView(entry: entry)
                            }
                            .listRowBackground(PryTheme.Colors.surface)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.removeDeeplinkEntry(entry.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    relaunchDeeplink(entry)
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                }
                                .tint(PryTheme.Colors.deeplinks)

                                Button {
                                    UIPasteboard.general.string = entry.url
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                .tint(PryTheme.Colors.accent)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .contentMargins(.vertical, PryTheme.Spacing.sm)
            }
        }
        .pryBackground()
        .searchable(text: $searchText, prompt: "URL, scheme, host...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSimulator = true
                } label: {
                    Image(systemName: "play.circle")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.deeplinks)
                }
            }
        }
        .sheet(isPresented: $showSimulator) {
            DeeplinkSimulatorView(store: store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(PryTheme.Colors.background)
        }
    }

    private func relaunchDeeplink(_ entry: DeeplinkEntry) {
        guard let url = URL(string: entry.url) else { return }
        store.logDeeplink(url: url)
        openURL(url)
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
        DeeplinkMonitorView(store: PryStore())
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
