import SwiftUI
import UIKit

struct UserDefaultsView: View {
    @State private var entries: [(key: String, value: String, type: String)] = []
    @State private var searchText = ""
    @State private var editingItem: EditItem?

    private struct EditItem: Identifiable {
        let id = UUID()
        let key: String
        var value: String
    }

    private var filteredEntries: [(key: String, value: String, type: String)] {
        guard !searchText.isEmpty else { return entries }
        let query = searchText.lowercased()
        return entries.filter {
            $0.key.lowercased().contains(query) ||
            $0.value.lowercased().contains(query)
        }
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView {
                    Label("No UserDefaults", systemImage: "tray")
                } description: {
                    Text("UserDefaults is empty")
                }
            } else {
                List {
                    ForEach(filteredEntries, id: \.key) { entry in
                        Button {
                            editingItem = EditItem(key: entry.key, value: entry.value)
                        } label: {
                            defaultsRow(entry)
                        }
                        .listRowBackground(PryTheme.Colors.surface)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                UserDefaults.standard.removeObject(forKey: entry.key)
                                loadDefaults()
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                UIPasteboard.general.string = entry.value
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .tint(PryTheme.Colors.accent)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .pryBackground()
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Key, value...")
        .onAppear { loadDefaults() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { loadDefaults() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.textSecondary)
                }
            }
        }
        .sheet(item: $editingItem) { item in
            UserDefaultsEditorView(key: item.key, initialValue: item.value) { newValue in
                UserDefaults.standard.set(newValue, forKey: item.key)
                loadDefaults()
            }
        }
    }

    private func defaultsRow(_ entry: (key: String, value: String, type: String)) -> some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            HStack {
                Text(entry.key)
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text(entry.type)
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }

            Text(entry.value)
                .font(PryTheme.Typography.codeSmall)
                .foregroundStyle(PryTheme.Colors.textSecondary)
                .lineLimit(2)
        }
        .padding(.vertical, PryTheme.Spacing.xs)
    }

    private func loadDefaults() {
        let dict = UserDefaults.standard.dictionaryRepresentation()
        entries = dict
            .sorted { $0.key < $1.key }
            .map { key, value in
                let type = typeLabel(for: value)
                let valueStr = String(describing: value)
                return (key: key, value: valueStr, type: type)
            }
    }

    private func typeLabel(for value: Any) -> String {
        switch value {
        case is Bool: return "Bool"
        case is Int: return "Int"
        case is Double: return "Double"
        case is String: return "String"
        case is Data: return "Data"
        case is Date: return "Date"
        case is [Any]: return "Array"
        case is [String: Any]: return "Dict"
        default: return "Other"
        }
    }
}

// MARK: - Editor Sheet

struct UserDefaultsEditorView: View {
    let key: String
    let onSave: (String) -> Void
    @State private var value: String
    @Environment(\.dismiss) private var dismiss

    init(key: String, initialValue: String, onSave: @escaping (String) -> Void) {
        self.key = key
        self.onSave = onSave
        self._value = State(initialValue: initialValue)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: PryTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                    Text("KEY")
                        .font(PryTheme.Typography.detail)
                        .fontWeight(.semibold)
                        .foregroundStyle(PryTheme.Colors.textSecondary)

                    Text(key)
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                        .padding(PryTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PryTheme.Colors.surface)
                        .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                }

                VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                    Text("VALUE")
                        .font(PryTheme.Typography.detail)
                        .fontWeight(.semibold)
                        .foregroundStyle(PryTheme.Colors.textSecondary)

                    TextEditor(text: $value)
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .padding(PryTheme.Spacing.sm)
                        .background(PryTheme.Colors.surface)
                        .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: PryTheme.Radius.md)
                                .stroke(PryTheme.Colors.border, lineWidth: 1)
                        )
                }

                Spacer()
            }
            .padding(PryTheme.Spacing.lg)
            .pryBackground()
            .navigationTitle("Edit Value")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(PryTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onSave(value)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(PryTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(PryTheme.Colors.accent)
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("UserDefaults") {
    NavigationStack {
        UserDefaultsView()
            .navigationTitle("UserDefaults")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
