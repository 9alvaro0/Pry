import SwiftUI

/// Sheet to pick a request to compare against.
struct DiffPickerSheet: View {
    let entries: [NetworkEntry]
    let currentEntry: NetworkEntry
    let onSelect: (NetworkEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredEntries: [NetworkEntry] {
        let others = entries.filter { $0.id != currentEntry.id }
        guard !searchText.isEmpty else { return others }
        let query = searchText.lowercased()
        return others.filter {
            $0.requestMethod.lowercased().contains(query) ||
            $0.displayPath.lowercased().contains(query) ||
            $0.requestURL.extractHost().lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredEntries) { entry in
                    Button {
                        onSelect(entry)
                        dismiss()
                    } label: {
                        HStack(spacing: InspectorTheme.Spacing.sm) {
                            Text(entry.requestMethod)
                                .font(InspectorTheme.Typography.code)
                                .fontWeight(.semibold)
                                .foregroundStyle(InspectorTheme.Colors.textSecondary)
                                .frame(width: 46, alignment: .leading)

                            Text(entry.displayPath)
                                .font(InspectorTheme.Typography.code)
                                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            if let code = entry.responseStatusCode {
                                Text("\(code)")
                                    .inspectorStatusBadge(code)
                            }

                            Text(entry.timestamp.relativeTimestamp)
                                .font(InspectorTheme.Typography.detail)
                                .foregroundStyle(InspectorTheme.Colors.textTertiary)
                        }
                    }
                    .listRowBackground(InspectorTheme.Colors.surface)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .inspectorBackground()
            .navigationTitle("Compare with")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search requests...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(InspectorTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }
}
