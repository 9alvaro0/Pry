import SwiftUI

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
                    .tint(PryTheme.Colors.warning)
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
                                    UIPasteboard.general.string = entry.rawPayload ?? entry.displayTitle
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                .tint(PryTheme.Colors.warning)
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
                        .foregroundStyle(PryTheme.Colors.warning)
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
                        .background(PryTheme.Colors.warning.opacity(PryTheme.Opacity.badge))
                        .foregroundStyle(PryTheme.Colors.warning)
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
