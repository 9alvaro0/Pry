import SwiftUI

/// Centralized view showing all active network rules (mocks + breakpoints).
struct NetworkRulesView: View {
    @Bindable var store: PryProStore

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
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.warning)
                }
            }
            .listRowBackground(PryTheme.Colors.surface)

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
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.syntaxBool)
                }
            }
            .listRowBackground(PryTheme.Colors.surface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .pryBackground()
    }

    // MARK: - Breakpoint Row

    private func breakpointRow(_ rule: BreakpointRule) -> some View {
        HStack(spacing: PryTheme.Spacing.md) {
            Image(systemName: "pause.circle.fill")
                .font(PryTheme.Typography.body)
                .foregroundStyle(rule.isEnabled ? PryTheme.Colors.warning : PryTheme.Colors.textTertiary)

            VStack(alignment: .leading, spacing: PryTheme.Spacing.xxs) {
                HStack(spacing: PryTheme.Spacing.sm) {
                    if let method = rule.method {
                        Text(method)
                            .font(PryTheme.Typography.codeSmall)
                            .fontWeight(.bold)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
                    }
                    Text(rule.urlPattern)
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                        .lineLimit(1)
                }
                Text(rule.pauseOn.rawValue)
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }

            Spacer()

            Toggle("", isOn: breakpointToggle(for: rule.id))
                .tint(PryTheme.Colors.warning)
                .labelsHidden()
        }
    }

    // MARK: - Mock Row

    private func mockRow(_ rule: MockRule) -> some View {
        HStack(spacing: PryTheme.Spacing.md) {
            Image(systemName: "theatermasks.fill")
                .font(PryTheme.Typography.body)
                .foregroundStyle(rule.isEnabled ? PryTheme.Colors.syntaxBool : PryTheme.Colors.textTertiary)

            VStack(alignment: .leading, spacing: PryTheme.Spacing.xxs) {
                HStack(spacing: PryTheme.Spacing.sm) {
                    if let method = rule.method {
                        Text(method)
                            .font(PryTheme.Typography.codeSmall)
                            .fontWeight(.bold)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
                    }
                    Text(rule.urlPattern)
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                        .lineLimit(1)
                }
                Text("\(rule.statusCode) \(rule.delay > 0 ? "+ \(String(format: "%.1fs", rule.delay)) delay" : "")")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }

            Spacer()

            Toggle("", isOn: mockToggle(for: rule.id))
                .tint(PryTheme.Colors.syntaxBool)
                .labelsHidden()
        }
    }

    // MARK: - Empty Row

    private func emptyRow(_ text: String, icon: String) -> some View {
        HStack(spacing: PryTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(PryTheme.Colors.textTertiary)
            Text(text)
                .font(PryTheme.Typography.body)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
    }

    // MARK: - Toggles

    private func breakpointToggle(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { store.breakpointRules.first { $0.id == id }?.isEnabled ?? false },
            set: { _ in store.toggleBreakpointRule(id) }
        )
    }

    private func mockToggle(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { store.mockRules.first { $0.id == id }?.isEnabled ?? false },
            set: { _ in store.toggleMockRule(id) }
        )
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Rules - Empty") {
    NavigationStack {
        NetworkRulesView(store: PryProStore())
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
