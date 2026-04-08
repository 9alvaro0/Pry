import SwiftUI
import UIKit

struct UserDefaultsView: View {
    @State private var entries: [(key: String, value: String, type: String)] = []
    @State private var searchText = ""
    @State private var editingKey: String?
    @State private var editValue = ""
    @State private var showEditor = false

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
                            editingKey = entry.key
                            editValue = entry.value
                            showEditor = true
                        } label: {
                            defaultsRow(entry)
                        }
                        .listRowBackground(InspectorTheme.Colors.surface)
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
                            .tint(InspectorTheme.Colors.accent)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .inspectorBackground()
        .searchable(text: $searchText, prompt: "Key, value...")
        .onAppear { loadDefaults() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { loadDefaults() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(InspectorTheme.Colors.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            if let key = editingKey {
                UserDefaultsEditorView(key: key, value: $editValue) {
                    UserDefaults.standard.set(editValue, forKey: key)
                    loadDefaults()
                }
            }
        }
    }

    private func defaultsRow(_ entry: (key: String, value: String, type: String)) -> some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
            HStack {
                Text(entry.key)
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text(entry.type)
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }

            Text(entry.value)
                .font(InspectorTheme.Typography.codeSmall)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)
                .lineLimit(2)
        }
        .padding(.vertical, InspectorTheme.Spacing.xs)
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
    @Binding var value: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.lg) {
                // Key (read-only)
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                    Text("KEY")
                        .font(InspectorTheme.Typography.detail)
                        .fontWeight(.semibold)
                        .foregroundStyle(InspectorTheme.Colors.textSecondary)

                    Text(key)
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.textPrimary)
                        .padding(InspectorTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(InspectorTheme.Colors.surface)
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                }

                // Value (editable)
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                    Text("VALUE")
                        .font(InspectorTheme.Typography.detail)
                        .fontWeight(.semibold)
                        .foregroundStyle(InspectorTheme.Colors.textSecondary)

                    TextEditor(text: $value)
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .padding(InspectorTheme.Spacing.sm)
                        .background(InspectorTheme.Colors.surface)
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: InspectorTheme.Radius.md)
                                .stroke(InspectorTheme.Colors.border, lineWidth: 1)
                        )
                }

                Spacer()
            }
            .padding(InspectorTheme.Spacing.lg)
            .inspectorBackground()
            .navigationTitle("Edit Value")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(InspectorTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onSave()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(InspectorTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(InspectorTheme.Colors.accent)
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
