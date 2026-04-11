import SwiftUI
import UIKit

@_spi(PryPro) public struct NetworkRequestDetailView: View {
    @_spi(PryPro) public let entry: NetworkEntry

    @Environment(\.pryStore) private var store
    @State private var selectedTab = 0
    @State private var toastMessage: String?
    @State private var pendingConflictAction: ProToolbarAction?

    private var proActions: [ProToolbarAction] {
        PryHooks.proDetailActions?(entry) ?? []
    }

    @_spi(PryPro) public init(entry: NetworkEntry) {
        self.entry = entry
    }

    @_spi(PryPro) public var body: some View {
        VStack(spacing: 0) {
            summaryHeader
                .padding(.horizontal, PryTheme.Spacing.lg)

            Divider().overlay(PryTheme.Colors.border)

            Picker("", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Request").tag(1)
                Text("Response").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, PryTheme.Spacing.lg)
            .padding(.vertical, PryTheme.Spacing.sm)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch selectedTab {
                    case 0:
                        proActionsSection(for: .overview)
                        NetworkDetailOverview(entry: entry)
                    case 1:
                        tabActions(for: .request, extra: curlAction)
                        NetworkDetailRequest(entry: entry)
                    case 2:
                        proActionsSection(for: .response)
                        NetworkDetailResponse(entry: entry)
                    default: EmptyView()
                    }
                }
                .padding(.horizontal, PryTheme.Spacing.lg)
                .padding(.bottom, PryTheme.Spacing.xl)
            }
        }
        .pryBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .modifier(ProDetailSheetModifier())
        .overlay(alignment: .top) {
            if let message = toastMessage {
                toastView(message)
            }
        }
        .animation(.easeInOut(duration: PryTheme.Animation.standard), value: toastMessage)
        .alert("Replace Rule?", isPresented: Binding(
            get: { pendingConflictAction != nil },
            set: { if !$0 { pendingConflictAction = nil } }
        )) {
            Button("Replace", role: .destructive) {
                guard let action = pendingConflictAction else { return }
                let conflicts = conflictingRules(for: action.id)
                for rule in conflicts { PryHooks.proDeleteRule?(rule.id) }
                executeAction(action)
                pendingConflictAction = nil
            }
            Button("Cancel", role: .cancel) { pendingConflictAction = nil }
        } message: {
            if let action = pendingConflictAction {
                let existing = action.id == "mock" ? "breakpoint" : "mock"
                Text("This will replace the active \(existing) for this request.")
            }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
            HStack(spacing: PryTheme.Spacing.sm) {
                if let statusCode = entry.responseStatusCode {
                    Text("\(statusCode)")
                        .pryStatusBadge(statusCode)
                    let desc = HTTPStatus.description(for: statusCode)
                    if !desc.isEmpty {
                        Text(desc)
                            .font(PryTheme.Typography.body)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
                    }
                } else if entry.responseError != nil {
                    statusPill("ERROR", color: PryTheme.Colors.error)
                } else {
                    statusPill("PENDING", color: PryTheme.Colors.pending)
                }

                Spacer()

                if let duration = entry.duration {
                    Text(duration.formattedDuration)
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.textSecondary)
                }
                if let size = entry.responseSize, size > 0 {
                    Text(size.formatBytes())
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.textSecondary)
                }
            }

            Text(entry.requestURL)
                .font(PryTheme.Typography.codeSmall)
                .foregroundStyle(PryTheme.Colors.textTertiary)
                .textSelection(.enabled)
                .lineLimit(2)

            Text(entry.timestamp.formatFullTimestamp())
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
        .padding(.vertical, PryTheme.Spacing.md)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("\(entry.requestMethod) \(entry.displayPath)")
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        ToolbarItem(placement: .topBarTrailing) {
            ShareLink(item: generateShareText()) {
                Image(systemName: "square.and.arrow.up")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(PryTheme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Tab Action Buttons

    private var curlAction: ActionItem {
        ActionItem(icon: "terminal.fill", title: "Copy as cURL", color: PryTheme.Colors.accent) {
            copyToClipboard(NetworkCurlGenerator.generate(for: entry))
        }
    }

    private struct ActionItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let color: Color
        let action: () -> Void
    }

    private var activeRules: [ProEntryRule] {
        PryHooks.proRulesForEntry?(entry) ?? []
    }

    private func rulesForTab(_ placement: ProToolbarAction.Placement) -> [ProEntryRule] {
        switch placement {
        case .request: activeRules.filter { $0.type == .breakpoint && $0.detail == "Request" }
        case .response: activeRules.filter { $0.type == .breakpoint && $0.detail == "Response" || $0.type == .mock }
        case .overview: []
        default: []
        }
    }

    private var hasResponseBreakpoint: Bool {
        activeRules.contains { $0.type == .breakpoint && ($0.detail == "Response" || $0.detail == "Both") }
    }

    private var hasMock: Bool {
        activeRules.contains { $0.type == .mock }
    }

    private func shouldHideAction(_ action: ProToolbarAction) -> Bool {
        switch action.id {
        case "breakpoint":
            activeRules.contains { $0.type == .breakpoint && $0.detail == "Request" }
        case "breakpoint-response":
            hasResponseBreakpoint
        case "mock":
            hasMock
        default:
            false
        }
    }

    private func executeAction(_ action: ProToolbarAction) {
        PryHooks.proDetailActionHandler?(action.id, entry)
        switch action.id {
        case "replay": showToast("Replayed")
        case "breakpoint", "breakpoint-response": showToast("Breakpoint added")
        default: break
        }
    }

    /// Returns the conflicting rule IDs to delete if this action proceeds.
    private func conflictingRules(for actionID: String) -> [ProEntryRule] {
        switch actionID {
        case "breakpoint-response" where hasMock:
            activeRules.filter { $0.type == .mock }
        case "mock" where hasResponseBreakpoint:
            activeRules.filter { $0.type == .breakpoint && ($0.detail == "Response" || $0.detail == "Both") }
        default:
            []
        }
    }

    @ViewBuilder
    private func tabActions(for placement: ProToolbarAction.Placement, extra: ActionItem? = nil) -> some View {
        let pro = proActions.filter { $0.placement == placement }
            .filter { !shouldHideAction($0) }
        let rules = rulesForTab(placement)
        let hasContent = !pro.isEmpty || extra != nil || !rules.isEmpty

        if hasContent {
            VStack(spacing: PryTheme.Spacing.sm) {
                // Active rules for this tab
                if !rules.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(rules) { rule in
                            if rule.id != rules.first?.id {
                                Divider().overlay(PryTheme.Colors.border)
                            }
                            ruleRow(rule)
                        }
                    }
                    .background(PryTheme.Colors.surface)
                    .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                    .pryGlowBorder(cornerRadius: PryTheme.Radius.md)
                }

                // Action buttons
                if !pro.isEmpty || extra != nil {
                    VStack(spacing: 0) {
                        if let extra {
                            actionRow(icon: extra.icon, title: extra.title, color: extra.color, action: extra.action)
                        }
                        ForEach(pro) { action in
                            if extra != nil || action.id != pro.first?.id {
                                Divider().overlay(PryTheme.Colors.border)
                            }
                            actionRow(icon: action.icon, title: action.title, color: PryTheme.Colors.accent) {
                                let conflicts = conflictingRules(for: action.id)
                                if !conflicts.isEmpty {
                                    pendingConflictAction = action
                                } else {
                                    executeAction(action)
                                }
                            }
                        }
                    }
                    .background(PryTheme.Colors.surface)
                    .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                    .pryGlowBorder(cornerRadius: PryTheme.Radius.md)
                }
            }
            .padding(.vertical, PryTheme.Spacing.md)
        }
    }

    @ViewBuilder
    private func proActionsSection(for placement: ProToolbarAction.Placement) -> some View {
        tabActions(for: placement)
    }

    private func ruleRow(_ rule: ProEntryRule) -> some View {
        HStack(spacing: PryTheme.Spacing.sm) {
            Image(systemName: rule.type == .breakpoint ? "pause.circle.fill" : "theatermasks.fill")
                .font(PryTheme.Typography.body)
                .foregroundStyle(rule.type == .breakpoint ? PryTheme.Colors.warning : PryTheme.Colors.syntaxBool)

            Text(rule.title)
                .font(PryTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(PryTheme.Colors.textPrimary)

            Text(rule.detail)
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)

            Spacer()

            Button { PryHooks.proToggleRule?(rule.id) } label: {
                Image(systemName: rule.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline)
                    .foregroundStyle(rule.isEnabled ? PryTheme.Colors.success : PryTheme.Colors.textTertiary)
            }

            Button { PryHooks.proDeleteRule?(rule.id) } label: {
                Image(systemName: "trash")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.error)
            }
        }
        .padding(.horizontal, PryTheme.Spacing.md)
        .frame(minHeight: 44)
    }

    private func actionRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: PryTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(title)
                    .font(PryTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(PryTheme.Colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }
            .padding(.horizontal, PryTheme.Spacing.md)
            .frame(minHeight: 48)
            .contentShape(.rect)
        }
    }

    // MARK: - Helpers

    private func statusPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(PryTheme.Typography.codeSmall)
            .fontWeight(.medium)
            .padding(.horizontal, PryTheme.Spacing.pip)
            .padding(.vertical, PryTheme.Spacing.xxs)
            .background(color.opacity(PryTheme.Opacity.badge))
            .foregroundStyle(color)
            .clipShape(.capsule)
    }

    private func toastView(_ message: String) -> some View {
        HStack(spacing: PryTheme.Spacing.xs) {
            Image(systemName: "checkmark")
                .font(PryTheme.Typography.detail)
            Text(message)
                .font(PryTheme.Typography.detail)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, PryTheme.Spacing.md)
        .padding(.vertical, PryTheme.Spacing.sm)
        .background(PryTheme.Colors.success)
        .clipShape(.capsule)
        .transition(.move(edge: .top).combined(with: .opacity))
        .padding(.top, PryTheme.Spacing.sm)
    }

    private func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(for: PryTheme.Animation.toastDismiss)
            toastMessage = nil
        }
    }

    private func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
        showToast("Copied")
    }

    private func generateShareText() -> String {
        var lines: [String] = []
        let path = entry.requestURL.extractPath()
        var summary = "\(entry.requestMethod) \(path)"
        if let statusCode = entry.responseStatusCode {
            let desc = HTTPStatus.description(for: statusCode)
            summary += " \u{2192} \(statusCode)"
            if !desc.isEmpty { summary += " \(desc)" }
        } else if entry.responseError != nil {
            summary += " \u{2192} ERROR"
        }
        if let duration = entry.duration {
            summary += " (\(duration.formattedDuration))"
        }
        lines.append(summary)
        lines.append(entry.requestURL)
        if let body = entry.requestBody, !body.isEmpty {
            lines.append("\n\u{2500}\u{2500} Request Body \u{2500}\u{2500}\n\(body)")
        }
        if let body = entry.responseBody, !body.isEmpty {
            lines.append("\n\u{2500}\u{2500} Response Body \u{2500}\u{2500}\n\(body)")
        }
        if let error = entry.responseError, !error.isEmpty {
            lines.append("\n\u{2500}\u{2500} Error \u{2500}\u{2500}\n\(error)")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Pro Detail Sheet Modifier

private struct ProDetailSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if let sheetHook = PryHooks.proDetailSheet {
            let sheet = sheetHook()
            content.sheet(isPresented: sheet.isPresented) { sheet.content() }
        } else {
            content
        }
    }
}

#if DEBUG
#Preview("Detail - Success") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockSuccess)
    }
}

#Preview("Detail - Error") {
    NavigationStack {
        NetworkRequestDetailView(entry: .mockError)
    }
}
#endif
