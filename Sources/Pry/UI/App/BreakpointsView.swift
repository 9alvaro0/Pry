import SwiftUI

/// Manages breakpoint rules — URL patterns that pause requests for editing.
struct BreakpointsView: View {
    @Bindable var store: PryStore

    @State private var showAddSheet = false

    var body: some View {
        List {
            if store.breakpointRules.isEmpty {
                Section {
                    VStack(spacing: PryTheme.Spacing.md) {
                        Image(systemName: "pause.circle")
                            .font(.system(size: PryTheme.FontSize.emptyState))
                            .foregroundStyle(PryTheme.Colors.textTertiary)
                        Text("No breakpoints")
                            .font(PryTheme.Typography.body)
                            .foregroundStyle(PryTheme.Colors.textTertiary)
                        Text("Add a breakpoint to pause and edit requests in real time")
                            .font(PryTheme.Typography.detail)
                            .foregroundStyle(PryTheme.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PryTheme.Spacing.xl)
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
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }
                .listRowBackground(PryTheme.Colors.surface)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .pryBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                        .font(PryTheme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(PryTheme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            BreakpointRuleEditor(store: store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(PryTheme.Colors.background)
        }
    }

    private func breakpointRow(_ rule: BreakpointRule) -> some View {
        HStack(spacing: PryTheme.Spacing.md) {
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

                HStack(spacing: PryTheme.Spacing.sm) {
                    Text(rule.pauseOn.rawValue)
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.warning)

                    if !rule.name.isEmpty {
                        Text(rule.name)
                            .font(PryTheme.Typography.detail)
                            .foregroundStyle(PryTheme.Colors.textTertiary)
                    }
                }
            }

            Spacer()

            Toggle("", isOn: toggleBinding(for: rule.id))
                .tint(PryTheme.Colors.warning)
                .labelsHidden()
        }
    }

    private func toggleBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { store.breakpointRules.first { $0.id == id }?.isEnabled ?? false },
            set: { _ in store.toggleBreakpointRule(id) }
        )
    }
}

// MARK: - Rule Editor

struct BreakpointRuleEditor: View {
    @Bindable var store: PryStore
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
                        .font(PryTheme.Typography.code)

                    TextField("URL pattern (e.g. /api/login)", text: $urlPattern)
                        .font(PryTheme.Typography.code)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .listRowBackground(PryTheme.Colors.surface)

                Section("Method") {
                    ForEach(methods, id: \.self) { m in
                        Button {
                            method = m
                        } label: {
                            HStack {
                                Text(m ?? "Any")
                                    .font(PryTheme.Typography.code)
                                    .foregroundStyle(PryTheme.Colors.textPrimary)
                                Spacer()
                                if method == m {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(PryTheme.Colors.accent)
                                }
                            }
                        }
                    }
                }
                .listRowBackground(PryTheme.Colors.surface)

                Section("Pause On") {
                    ForEach(BreakpointRule.PauseType.allCases, id: \.self) { type in
                        Button {
                            pauseOn = type
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: PryTheme.Spacing.xxs) {
                                    Text(type.rawValue)
                                        .font(PryTheme.Typography.body)
                                        .foregroundStyle(PryTheme.Colors.textPrimary)
                                    Text(type.description)
                                        .font(PryTheme.Typography.detail)
                                        .foregroundStyle(PryTheme.Colors.textTertiary)
                                }
                                Spacer()
                                if pauseOn == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(PryTheme.Colors.accent)
                                }
                            }
                        }
                    }
                }
                .listRowBackground(PryTheme.Colors.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .pryBackground()
            .navigationTitle("New Breakpoint")
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
                            .font(PryTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(PryTheme.Colors.accent)
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
