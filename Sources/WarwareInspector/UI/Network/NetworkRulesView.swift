import SwiftUI

/// Centralized view showing all active network rules (mocks + breakpoints).
struct NetworkRulesView: View {
    @Bindable var store: InspectorStore

    var body: some View {
        List {
            // Breakpoints
            Section {
                if store.breakpointRules.isEmpty {
                    emptyRow("No breakpoints", icon: "pause.circle")
                } else {
                    ForEach(store.breakpointRules) { rule in
                        breakpointRow(rule)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            store.removeBreakpointRule(store.breakpointRules[index].id)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Breakpoints")
                    Spacer()
                    Text("\(store.breakpointRules.filter(\.isEnabled).count) active")
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.warning)
                }
            }
            .listRowBackground(InspectorTheme.Colors.surface)

            // Mock Rules
            Section {
                if store.mockRules.isEmpty {
                    emptyRow("No mocks", icon: "theatermasks")
                } else {
                    ForEach(store.mockRules) { rule in
                        mockRow(rule)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            store.removeMockRule(store.mockRules[index].id)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Mocks")
                    Spacer()
                    Text("\(store.mockRules.filter(\.isEnabled).count) active")
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.syntaxBool)
                }
            }
            .listRowBackground(InspectorTheme.Colors.surface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .inspectorBackground()
    }

    // MARK: - Breakpoint Row

    private func breakpointRow(_ rule: BreakpointRule) -> some View {
        HStack(spacing: InspectorTheme.Spacing.md) {
            Image(systemName: "pause.circle.fill")
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(rule.isEnabled ? InspectorTheme.Colors.warning : InspectorTheme.Colors.textTertiary)

            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                HStack(spacing: InspectorTheme.Spacing.sm) {
                    if let method = rule.method {
                        Text(method)
                            .font(InspectorTheme.Typography.codeSmall)
                            .fontWeight(.bold)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)
                    }
                    Text(rule.urlPattern)
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.textPrimary)
                        .lineLimit(1)
                }
                Text(rule.pauseOn.rawValue)
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }

            Spacer()

            Toggle("", isOn: breakpointToggle(for: rule.id))
                .tint(InspectorTheme.Colors.warning)
                .labelsHidden()
        }
    }

    // MARK: - Mock Row

    private func mockRow(_ rule: MockRule) -> some View {
        HStack(spacing: InspectorTheme.Spacing.md) {
            Image(systemName: "theatermasks.fill")
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(rule.isEnabled ? InspectorTheme.Colors.syntaxBool : InspectorTheme.Colors.textTertiary)

            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                HStack(spacing: InspectorTheme.Spacing.sm) {
                    if let method = rule.method {
                        Text(method)
                            .font(InspectorTheme.Typography.codeSmall)
                            .fontWeight(.bold)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)
                    }
                    Text(rule.urlPattern)
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.textPrimary)
                        .lineLimit(1)
                }
                Text("\(rule.statusCode) \(rule.delay > 0 ? "+ \(String(format: "%.1fs", rule.delay)) delay" : "")")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }

            Spacer()

            Toggle("", isOn: mockToggle(for: rule.id))
                .tint(InspectorTheme.Colors.syntaxBool)
                .labelsHidden()
        }
    }

    // MARK: - Empty Row

    private func emptyRow(_ text: String, icon: String) -> some View {
        HStack(spacing: InspectorTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
            Text(text)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
    }

    // MARK: - Toggles

    private func breakpointToggle(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { store.breakpointRules.first { $0.id == id }?.isEnabled ?? false },
            set: { newValue in
                if let index = store.breakpointRules.firstIndex(where: { $0.id == id }) {
                    store.breakpointRules[index].isEnabled = newValue
                    store.syncBreakpointRulesPublic()
                }
            }
        )
    }

    private func mockToggle(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { store.mockRules.first { $0.id == id }?.isEnabled ?? false },
            set: { newValue in
                if let index = store.mockRules.firstIndex(where: { $0.id == id }) {
                    store.mockRules[index].isEnabled = newValue
                    InspectorURLProtocol.mockRules = store.mockRules
                    InspectorURLProtocol.isMockingEnabled = store.isMockingEnabled
                }
            }
        )
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Rules - Empty") {
    NavigationStack {
        NetworkRulesView(store: InspectorStore())
            .navigationTitle("Rules")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Rules - With Rules") {
    NavigationStack {
        NetworkRulesView(store: .preview)
            .navigationTitle("Rules")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
