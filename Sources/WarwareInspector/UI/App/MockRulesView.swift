import SwiftUI

/// List view for managing mock rules that intercept network requests.
struct MockRulesView: View {
    @Bindable var store: InspectorStore

    @State private var editingRule: MockRule?
    @State private var isAddingNew = false

    var body: some View {
        List {
            // Enable mocking toggle
            Section {
                Toggle(isOn: Binding(
                    get: { store.isMockingEnabled },
                    set: { newValue in
                        store.isMockingEnabled = newValue
                        syncToProtocol()
                    }
                )) {
                    HStack(spacing: InspectorTheme.Spacing.sm) {
                        Image(systemName: "theatermasks")
                            .font(InspectorTheme.Typography.body)
                            .foregroundStyle(InspectorTheme.Colors.syntaxBool)
                        Text("Enable Mocking")
                            .font(InspectorTheme.Typography.body)
                            .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    }
                }
                .tint(InspectorTheme.Colors.syntaxBool)
            }
            .listRowBackground(InspectorTheme.Colors.surface)

            // Rules list
            if store.mockRules.isEmpty {
                Section {
                    emptyState
                }
                .listRowBackground(InspectorTheme.Colors.surface)
            } else {
                Section {
                    ForEach(store.mockRules) { rule in
                        Button {
                            editingRule = rule
                        } label: {
                            ruleRow(rule)
                        }
                    }
                    .onDelete(perform: deleteRules)
                } header: {
                    Text("Rules (\(store.mockRules.count))")
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }
                .listRowBackground(InspectorTheme.Colors.surface)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .inspectorBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingNew = true
                } label: {
                    Image(systemName: "plus")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(InspectorTheme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $isAddingNew) {
            NavigationStack {
                MockRuleEditorView(
                    onSave: { rule in
                        store.addMockRule(rule)
                        syncToProtocol()
                        isAddingNew = false
                    },
                    onCancel: { isAddingNew = false }
                )
                .navigationTitle("New Mock Rule")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(item: $editingRule) { rule in
            NavigationStack {
                MockRuleEditorView(
                    existingRule: rule,
                    onSave: { updated in
                        if let index = store.mockRules.firstIndex(where: { $0.id == updated.id }) {
                            store.mockRules[index] = updated
                        }
                        syncToProtocol()
                        editingRule = nil
                    },
                    onCancel: { editingRule = nil }
                )
                .navigationTitle("Edit Mock Rule")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    // MARK: - Rule Row

    private func ruleRow(_ rule: MockRule) -> some View {
        HStack(spacing: InspectorTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                // Line 1: Name or URL pattern
                Text(rule.name.isEmpty ? rule.urlPattern : rule.name)
                    .font(InspectorTheme.Typography.code)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    .lineLimit(1)

                // Line 2: Method badge + Status code badge + URL pattern (if name is shown)
                HStack(spacing: InspectorTheme.Spacing.xs) {
                    if let method = rule.method, !method.isEmpty {
                        Text(method)
                            .font(InspectorTheme.Typography.codeSmall)
                            .fontWeight(.semibold)
                            .foregroundStyle(InspectorTheme.Colors.methodColor(method))
                    } else {
                        Text("ANY")
                            .font(InspectorTheme.Typography.codeSmall)
                            .fontWeight(.semibold)
                            .foregroundStyle(InspectorTheme.Colors.textTertiary)
                    }

                    Text("\(rule.statusCode)")
                        .inspectorStatusBadge(rule.statusCode)

                    if !rule.name.isEmpty && !rule.urlPattern.isEmpty {
                        Text(rule.urlPattern)
                            .font(InspectorTheme.Typography.detail)
                            .foregroundStyle(InspectorTheme.Colors.textTertiary)
                            .lineLimit(1)
                    }

                    if rule.delay > 0 {
                        Text(String(format: "%.1fs", rule.delay))
                            .font(InspectorTheme.Typography.detail)
                            .foregroundStyle(InspectorTheme.Colors.warning)
                    }
                }
            }

            Spacer()

            // Enabled toggle
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { newValue in
                    if let index = store.mockRules.firstIndex(where: { $0.id == rule.id }) {
                        store.mockRules[index].isEnabled = newValue
                        syncToProtocol()
                    }
                }
            ))
            .labelsHidden()
            .tint(InspectorTheme.Colors.syntaxBool)
        }
        .padding(.vertical, InspectorTheme.Spacing.xxs)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: InspectorTheme.Spacing.md) {
            Image(systemName: "theatermasks")
                .font(.system(size: 32))
                .foregroundStyle(InspectorTheme.Colors.textTertiary)

            Text("No Mock Rules")
                .font(InspectorTheme.Typography.subheading)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)

            Text("Tap + to create a mock rule that intercepts\nmatching network requests.")
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, InspectorTheme.Spacing.xxl)
    }

    // MARK: - Actions

    private func deleteRules(at offsets: IndexSet) {
        store.mockRules.remove(atOffsets: offsets)
        syncToProtocol()
    }

    private func syncToProtocol() {
        InspectorURLProtocol.isMockingEnabled = store.isMockingEnabled
        InspectorURLProtocol.mockRules = store.mockRules
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Mock Rules - With Rules") {
    NavigationStack {
        MockRulesView(store: {
            let store = InspectorStore()
            store.addMockRule(.mockUsersSuccess)
            store.addMockRule(.mockCartError)
            store.isMockingEnabled = true
            return store
        }())
        .navigationTitle("Mock Rules")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Mock Rules - Empty") {
    NavigationStack {
        MockRulesView(store: InspectorStore())
            .navigationTitle("Mock Rules")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
