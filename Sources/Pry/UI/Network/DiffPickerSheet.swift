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
                        HStack(spacing: PryTheme.Spacing.sm) {
                            Text(entry.requestMethod)
                                .font(PryTheme.Typography.code)
                                .fontWeight(.semibold)
                                .foregroundStyle(PryTheme.Colors.textSecondary)
                                .frame(width: 46, alignment: .leading)

                            Text(entry.displayPath)
                                .font(PryTheme.Typography.code)
                                .foregroundStyle(PryTheme.Colors.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            if let code = entry.responseStatusCode {
                                Text("\(code)")
                                    .pryStatusBadge(code)
                            }

                            Text(entry.timestamp.relativeTimestamp)
                                .font(PryTheme.Typography.detail)
                                .foregroundStyle(PryTheme.Colors.textTertiary)
                        }
                    }
                    .listRowBackground(PryTheme.Colors.surface)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .pryBackground()
            .navigationTitle("Compare with")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search requests...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(PryTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }
}
