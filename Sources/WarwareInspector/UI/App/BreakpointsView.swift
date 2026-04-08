import SwiftUI

/// Manages breakpoint rules — URL patterns that pause requests for editing.
struct BreakpointsView: View {
    @Bindable var store: InspectorStore

    @State private var showAddSheet = false

    var body: some View {
        List {
            if store.breakpointRules.isEmpty {
                Section {
                    VStack(spacing: InspectorTheme.Spacing.md) {
                        Image(systemName: "pause.circle")
                            .font(.system(size: InspectorTheme.FontSize.emptyState))
                            .foregroundStyle(InspectorTheme.Colors.textTertiary)
                        Text("No breakpoints")
                            .font(InspectorTheme.Typography.body)
                            .foregroundStyle(InspectorTheme.Colors.textTertiary)
                        Text("Add a breakpoint to pause and edit requests in real time")
                            .font(InspectorTheme.Typography.detail)
                            .foregroundStyle(InspectorTheme.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, InspectorTheme.Spacing.xl)
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    ForEach(store.breakpointRules) { rule in
                        breakpointRow(rule)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            store.removeBreakpointRule(store.breakpointRules[index].id)
                        }
                    }
                } footer: {
                    Text("Matching requests will pause and open an editor before being sent.")
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
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                        .font(InspectorTheme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(InspectorTheme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            BreakpointRuleEditor(store: store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(InspectorTheme.Colors.background)
        }
    }

    private func breakpointRow(_ rule: BreakpointRule) -> some View {
        HStack(spacing: InspectorTheme.Spacing.md) {
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

                HStack(spacing: InspectorTheme.Spacing.sm) {
                    Text(rule.pauseOn.rawValue)
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.warning)

                    if !rule.name.isEmpty {
                        Text(rule.name)
                            .font(InspectorTheme.Typography.detail)
                            .foregroundStyle(InspectorTheme.Colors.textTertiary)
                    }
                }
            }

            Spacer()

            Toggle("", isOn: toggleBinding(for: rule.id))
                .tint(InspectorTheme.Colors.warning)
                .labelsHidden()
        }
    }

    private func toggleBinding(for id: UUID) -> Binding<Bool> {
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
}

// MARK: - Rule Editor

struct BreakpointRuleEditor: View {
    @Bindable var store: InspectorStore
    var prefillEntry: NetworkEntry?

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var urlPattern = ""
    @State private var method: String?
    @State private var pauseOn: BreakpointRule.PauseType = .request
    @State private var didPrefill = false

    private let methods = [nil, "GET", "POST", "PUT", "DELETE", "PATCH"]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Name (optional)", text: $name)
                        .font(InspectorTheme.Typography.code)

                    TextField("URL pattern (e.g. /api/login)", text: $urlPattern)
                        .font(InspectorTheme.Typography.code)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .listRowBackground(InspectorTheme.Colors.surface)

                Section("Method") {
                    ForEach(methods, id: \.self) { m in
                        Button {
                            method = m
                        } label: {
                            HStack {
                                Text(m ?? "Any")
                                    .font(InspectorTheme.Typography.code)
                                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                                Spacer()
                                if method == m {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(InspectorTheme.Colors.accent)
                                }
                            }
                        }
                    }
                }
                .listRowBackground(InspectorTheme.Colors.surface)

                Section("Pause On") {
                    ForEach(BreakpointRule.PauseType.allCases, id: \.self) { type in
                        Button {
                            pauseOn = type
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                                    Text(type.rawValue)
                                        .font(InspectorTheme.Typography.body)
                                        .foregroundStyle(InspectorTheme.Colors.textPrimary)
                                    Text(type.description)
                                        .font(InspectorTheme.Typography.detail)
                                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                                }
                                Spacer()
                                if pauseOn == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(InspectorTheme.Colors.accent)
                                }
                            }
                        }
                    }
                }
                .listRowBackground(InspectorTheme.Colors.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .inspectorBackground()
            .navigationTitle("New Breakpoint")
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
                        let rule = BreakpointRule(
                            name: name,
                            urlPattern: urlPattern,
                            method: method,
                            pauseOn: pauseOn
                        )
                        store.addBreakpointRule(rule)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(InspectorTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(InspectorTheme.Colors.accent)
                    }
                    .disabled(urlPattern.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                guard !didPrefill, let entry = prefillEntry else { return }
                didPrefill = true
                urlPattern = entry.requestURL.extractPath()
                method = entry.requestMethod
                name = "\(entry.requestMethod) \(entry.requestURL.extractPath())"
            }
        }
    }
}

// MARK: - PauseType Description

extension BreakpointRule.PauseType {
    var description: String {
        switch self {
        case .request: "Pause before sending the request"
        case .response: "Pause after receiving the response"
        case .both: "Pause on both request and response"
        }
    }
}
