import SwiftUI
import UserNotifications
import UIKit

struct PushNotificationSimulatorView: View {
    @Bindable var store: PryStore

    @Environment(\.dismiss) private var dismiss

    // Mode
    @State private var mode: InputMode = .fields

    // Fields mode
    @State private var titleInput = ""
    @State private var bodyInput = ""
    @State private var subtitleInput = ""
    @State private var badgeInput = ""
    @State private var soundEnabled = true
    @State private var categoryInput = ""
    @State private var threadInput = ""
    @State private var customPayloadInput = ""
    @State private var showAdvanced = false

    // JSON mode
    @State private var rawJSONInput = ""
    @State private var jsonError: String?

    // Delay
    @State private var delaySeconds: Double = 1

    // State
    @State private var permissionGranted = false
    @State private var sent = false

    private enum InputMode: String, CaseIterable {
        case fields = "Fields"
        case json = "JSON"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.lg) {
                    // Mode picker
                    Picker("", selection: $mode) {
                        ForEach(InputMode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)

                    if mode == .fields {
                        fieldsContent
                    } else {
                        jsonContent
                    }

                    // Delay slider
                    delaySection

                    // Send button
                    Button {
                        simulate()
                    } label: {
                        HStack {
                            Image(systemName: sent ? "checkmark.circle.fill" : "bell.badge.fill")
                                .font(PryTheme.Typography.body)
                            Text(sent ? "Sent!" : "Send Notification")
                                .font(PryTheme.Typography.subheading)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PryTheme.Spacing.md)
                        .background(sent ? PryTheme.Colors.success : PryTheme.Colors.accent)
                        .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                    }
                    .disabled(isSendDisabled)
                    .opacity(isSendDisabled ? PryTheme.Opacity.overlay : 1)

                    if !permissionGranted {
                        Text("Notification permissions needed for real delivery. It will still be logged.")
                            .font(PryTheme.Typography.detail)
                            .foregroundStyle(PryTheme.Colors.textTertiary)
                    }
                }
                .padding(PryTheme.Spacing.lg)
            }
            .pryBackground()
            .navigationTitle("Simulate Push")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(PryTheme.Typography.body)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
                    }
                }
            }
            .onAppear { checkPermissions() }
        }
    }

    // MARK: - Fields Mode

    private var fieldsContent: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.md) {
            inputField("Title", placeholder: "Flash Sale!", text: $titleInput)
            inputField("Body", placeholder: "50% off all items", text: $bodyInput)
            inputField("Subtitle", placeholder: "Limited Time", text: $subtitleInput)

            Button {
                withAnimation { showAdvanced.toggle() }
            } label: {
                HStack {
                    Text("Advanced")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.textSecondary)
                    Spacer()
                    Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }
            }

            if showAdvanced {
                inputField("Badge", placeholder: "3", text: $badgeInput)
                    .keyboardType(.numberPad)

                HStack {
                    Text("Sound")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.textSecondary)
                    Spacer()
                    Toggle("", isOn: $soundEnabled)
                        .tint(PryTheme.Colors.accent)
                }

                inputField("Category", placeholder: "PROMO", text: $categoryInput)
                inputField("Thread ID", placeholder: "marketing", text: $threadInput)
            }
        }
    }

    // MARK: - Delay Section

    private var delaySection: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            HStack {
                fieldLabel("Delay")
                Spacer()
                Text(delayLabel)
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.accent)
            }

            Slider(value: $delaySeconds, in: 1...15, step: 1)
                .tint(PryTheme.Colors.accent)

            Text("Use delays > 3s to background the app and see notifications land.")
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
    }

    private var delayLabel: String {
        let seconds = Int(delaySeconds)
        return "\(seconds)s"
    }

    // MARK: - JSON Mode

    private var jsonContent: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
            fieldLabel("APNs Payload")

            TextEditor(text: $rawJSONInput)
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: PryTheme.Size.editorMinHeight)
                .padding(PryTheme.Spacing.sm)
                .background(PryTheme.Colors.surface)
                .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: PryTheme.Radius.md)
                        .stroke(jsonError != nil ? PryTheme.Colors.error : PryTheme.Colors.border, lineWidth: 1)
                )
                .onChange(of: rawJSONInput) { validateJSON() }

            if let error = jsonError {
                Text(error)
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.error)
            } else if !rawJSONInput.isEmpty {
                Text("Valid JSON")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.success)
            }

            Text("""
            Paste a full APNs payload:
            {
              "aps": {
                "alert": {"title": "...", "body": "..."},
                "badge": 1, "sound": "default"
              },
              "custom_key": "value"
            }
            """)
            .font(PryTheme.Typography.codeSmall)
            .foregroundStyle(PryTheme.Colors.textTertiary)
        }
    }

    // MARK: - Shared Components

    private var isSendDisabled: Bool {
        if mode == .fields {
            return titleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   bodyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return rawJSONInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || jsonError != nil
        }
    }

    private func inputField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            fieldLabel(label)
            TextField(placeholder, text: text)
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(PryTheme.Spacing.md)
                .background(PryTheme.Colors.surface)
                .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: PryTheme.Radius.md)
                        .stroke(PryTheme.Colors.border, lineWidth: 1)
                )
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(PryTheme.Typography.detail)
            .fontWeight(.semibold)
            .textCase(.uppercase)
            .tracking(PryTheme.Text.tracking)
            .foregroundStyle(PryTheme.Colors.textSecondary)
    }

    // MARK: - Validation

    private func validateJSON() {
        let text = rawJSONInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { jsonError = nil; return }
        guard let data = text.data(using: .utf8) else { jsonError = "Invalid text"; return }
        do {
            let obj = try JSONSerialization.jsonObject(with: data)
            guard obj is [String: Any] else { jsonError = "Must be a JSON object"; return }
            jsonError = nil
        } catch {
            jsonError = "Invalid JSON"
        }
    }

    // MARK: - Permissions

    private func checkPermissions() {
        Task {
            let status = await UNUserNotificationCenter.current().currentAuthorizationStatus()
            await MainActor.run {
                permissionGranted = status == .authorized
            }
        }
    }

    // MARK: - Simulate

    private func simulate() {
        if mode == .fields {
            simulateFromFields()
        } else {
            simulateFromJSON()
        }

        withAnimation { sent = true }
        Task {
            try? await Task.sleep(for: PryTheme.Animation.toastDismiss)
            withAnimation { sent = false }
        }
    }

    private func simulateFromFields() {
        let title = titleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = bodyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let subtitle = subtitleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let badge = Int(badgeInput.trimmingCharacters(in: .whitespacesAndNewlines))
        let category = categoryInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let thread = threadInput.trimmingCharacters(in: .whitespacesAndNewlines)

        let content = UNMutableNotificationContent()
        if !title.isEmpty { content.title = title }
        if !body.isEmpty { content.body = body }
        if !subtitle.isEmpty { content.subtitle = subtitle }
        if let badge { content.badge = NSNumber(value: badge) }
        if soundEnabled { content.sound = .default }
        if !category.isEmpty { content.categoryIdentifier = category }
        if !thread.isEmpty { content.threadIdentifier = thread }
        content.userInfo = ["pry_simulated": true]
        content.interruptionLevel = .timeSensitive

        scheduleAndLog(content: content, extraUserInfo: [:])
    }

    private func simulateFromJSON() {
        let text = rawJSONInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        let content = UNMutableNotificationContent()
        var allUserInfo = json

        if let aps = json["aps"] as? [String: Any] {
            if let alert = aps["alert"] as? [String: Any] {
                if let t = alert["title"] as? String { content.title = t }
                if let b = alert["body"] as? String { content.body = b }
                if let s = alert["subtitle"] as? String { content.subtitle = s }
            } else if let alert = aps["alert"] as? String {
                content.body = alert
            }

            if let b = aps["badge"] as? Int { content.badge = NSNumber(value: b) }
            if aps["sound"] != nil { content.sound = .default }
            if let c = aps["category"] as? String { content.categoryIdentifier = c }
            if let t = aps["thread-id"] as? String { content.threadIdentifier = t }
        }

        allUserInfo["pry_simulated"] = true
        content.userInfo = allUserInfo
        content.interruptionLevel = .timeSensitive

        let customKeys = json.filter { $0.key != "aps" }
        scheduleAndLog(content: content, extraUserInfo: customKeys)
    }

    private func scheduleAndLog(content: UNMutableNotificationContent, extraUserInfo: [String: Any]) {
        // Note: we don't log directly. The notification will fire and the
        // delegate (proxy or fallback) will log it via willPresent.
        // This avoids duplicate logs.
        Task {
            let center = UNUserNotificationCenter.current()

            if !permissionGranted {
                let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
                await MainActor.run { permissionGranted = granted }
                guard granted else {
                    // Permission denied — log directly as fallback so user sees something
                    await logDirectly(content: content)
                    return
                }
            }

            let interval = max(1, delaySeconds)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(
                identifier: "pry-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    @MainActor
    private func logDirectly(content: UNMutableNotificationContent) {
        store.logPushNotification(
            title: content.title.isEmpty ? nil : content.title,
            body: content.body.isEmpty ? nil : content.body,
            subtitle: content.subtitle.isEmpty ? nil : content.subtitle,
            badge: content.badge?.intValue,
            sound: content.sound != nil ? "default" : nil,
            categoryIdentifier: content.categoryIdentifier.isEmpty ? nil : content.categoryIdentifier,
            threadIdentifier: content.threadIdentifier.isEmpty ? nil : content.threadIdentifier,
            userInfo: content.userInfo as? [String: Any] ?? [:]
        )
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Simulator") {
    PushNotificationSimulatorView(store: PryStore())
        .presentationBackground(PryTheme.Colors.background)
}
#endif
