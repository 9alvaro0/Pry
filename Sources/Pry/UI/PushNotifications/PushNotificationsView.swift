import SwiftUI
import UserNotifications

struct PushNotificationsView: View {
    @Bindable var store: PryStore

    @State private var searchText: String = ""
    @State private var showSimulator = false

    private var filteredEntries: [PushNotificationEntry] {
        guard !searchText.isEmpty else { return store.pushNotificationEntries }
        let query = searchText.lowercased()

        return store.pushNotificationEntries.filter { entry in
            (entry.title?.lowercased().contains(query) ?? false) ||
            (entry.body?.lowercased().contains(query) ?? false) ||
            (entry.categoryIdentifier?.lowercased().contains(query) ?? false)
        }
    }

    var body: some View {
        Group {
            if store.pushNotificationEntries.isEmpty {
                ContentUnavailableView {
                    Label("No push notifications", systemImage: "bell.badge")
                } description: {
                    Text("Push notifications will appear here as the app receives them")
                } actions: {
                    Button {
                        showSimulator = true
                    } label: {
                        Label("Simulate", systemImage: "play.fill")
                            .font(PryTheme.Typography.body)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(PryTheme.Colors.accent)
                }
            } else {
                List {
                    Section {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(destination: PushNotificationDetailView(entry: entry)) {
                                PushNotificationRowView(entry: entry)
                            }
                            .listRowBackground(PryTheme.Colors.surface)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.removePushEntry(entry.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    relaunchNotification(entry)
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                }
                                .tint(PryTheme.Colors.accent)

                                Button {
                                    UIPasteboard.general.string = apnsPayload(for: entry)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                .tint(PryTheme.Colors.accent)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .contentMargins(.vertical, PryTheme.Spacing.sm)
            }
        }
        .pryBackground()
        .searchable(text: $searchText, prompt: "Title, body, category...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSimulator = true
                } label: {
                    Image(systemName: "play.circle")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showSimulator) {
            PushNotificationSimulatorView(store: store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(PryTheme.Colors.background)
        }
    }

    // MARK: - Helpers

    /// Builds an APNs-style JSON payload from the entry that can be pasted
    /// into the simulator's JSON mode.
    private func apnsPayload(for entry: PushNotificationEntry) -> String {
        if let raw = entry.rawPayload, !raw.isEmpty { return raw }

        var alert: [String: Any] = [:]
        if let title = entry.title { alert["title"] = title }
        if let body = entry.body { alert["body"] = body }
        if let subtitle = entry.subtitle { alert["subtitle"] = subtitle }

        var aps: [String: Any] = [:]
        if !alert.isEmpty { aps["alert"] = alert }
        if let badge = entry.badge { aps["badge"] = badge }
        if entry.sound != nil { aps["sound"] = "default" }
        if let category = entry.categoryIdentifier { aps["category"] = category }
        if let thread = entry.threadIdentifier { aps["thread-id"] = thread }

        var payload: [String: Any] = ["aps": aps]
        for (key, value) in entry.userInfo where key != "pry_simulated" {
            payload[key] = value
        }

        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
            return entry.displayTitle
        }
        return json
    }

    /// Re-schedules a notification from a captured entry so it fires again.
    private func relaunchNotification(_ entry: PushNotificationEntry) {
        let content = UNMutableNotificationContent()
        if let title = entry.title { content.title = title }
        if let body = entry.body { content.body = body }
        if let subtitle = entry.subtitle { content.subtitle = subtitle }
        if let badge = entry.badge { content.badge = NSNumber(value: badge) }
        if entry.sound != nil { content.sound = .default }
        if let category = entry.categoryIdentifier { content.categoryIdentifier = category }
        if let thread = entry.threadIdentifier { content.threadIdentifier = thread }
        content.userInfo = ["pry_simulated": true]
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pry-relaunch-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        Task {
            let center = UNUserNotificationCenter.current()
            let status = await center.currentAuthorizationStatus()
            if status != .authorized {
                _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            }
            try? await center.add(request)
        }
    }
}

// MARK: - Row

private struct PushNotificationRowView: View {
    let entry: PushNotificationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            // Line 1: title
            Text(entry.displayTitle)
                .font(PryTheme.Typography.code)
                .foregroundStyle(
                    entry.title != nil
                        ? PryTheme.Colors.textPrimary
                        : PryTheme.Colors.textTertiary
                )
                .lineLimit(1)

            // Line 2: body
            Text(entry.displayBody)
                .font(PryTheme.Typography.codeSmall)
                .foregroundStyle(PryTheme.Colors.textSecondary)
                .lineLimit(2)

            // Line 3: badges + timestamp
            HStack(spacing: PryTheme.Spacing.sm) {
                if let badge = entry.badge {
                    Text("badge: \(badge)")
                        .font(PryTheme.Typography.detail)
                        .padding(.horizontal, PryTheme.Spacing.pip)
                        .padding(.vertical, PryTheme.Spacing.xxs)
                        .background(PryTheme.Colors.accent.opacity(PryTheme.Opacity.badge))
                        .foregroundStyle(PryTheme.Colors.accent)
                        .clipShape(.capsule)
                }

                if let category = entry.categoryIdentifier, !category.isEmpty {
                    Text(category)
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }

                Spacer()

                Text(entry.timestamp.relativeTimestamp)
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }
        }
        .padding(.vertical, PryTheme.Spacing.xs)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Push - With Data") {
    NavigationStack {
        PushNotificationsView(store: .pushOnly)
            .navigationTitle("Push Notifications")
    }
}

#Preview("Push - Empty") {
    NavigationStack {
        PushNotificationsView(store: PryStore())
            .navigationTitle("Push Notifications")
    }
}

#Preview("Push - Full") {
    NavigationStack {
        PushNotificationsView(store: .preview)
            .navigationTitle("Push Notifications")
    }
}
#endif
