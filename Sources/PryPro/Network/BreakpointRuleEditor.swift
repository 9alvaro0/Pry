import SwiftUI

/// Simple form to create a breakpoint from an existing network request.
/// URL, method, and name are derived from the request automatically.
/// The user only chooses when to pause (request, response, or both).
struct BreakpointRuleEditor: View {
    @Bindable var store: PryProStore
    let entry: NetworkEntry

    @Environment(\.dismiss) private var dismiss
    @State private var pauseOn: BreakpointRule.PauseType = .request

    var body: some View {
        NavigationStack {
            List {
                Section {
                    requestSummary
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
            .navigationTitle("Add Breakpoint")
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
                            name: "\(entry.requestMethod) \(entry.requestURL.extractPath())",
                            urlPattern: entry.requestURL.extractPath(),
                            method: entry.requestMethod,
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
                }
            }
        }
    }

    private var requestSummary: some View {
        HStack(spacing: PryTheme.Spacing.sm) {
            Text(entry.requestMethod)
                .font(PryTheme.Typography.code)
                .fontWeight(.semibold)
                .foregroundStyle(PryTheme.Colors.textSecondary)

            Text(entry.requestURL.extractPath())
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
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
