import SwiftUI

/// Form to create or edit a breakpoint rule.
/// Can be pre-filled from an existing NetworkEntry for contextual creation.
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
