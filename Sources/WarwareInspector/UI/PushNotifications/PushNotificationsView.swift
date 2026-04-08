import SwiftUI

struct PushNotificationsView: View {
    @Bindable var store: InspectorStore

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
                            .font(InspectorTheme.Typography.body)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(InspectorTheme.Colors.warning)
                }
            } else {
                List {
                    Section {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(destination: PushNotificationDetailView(entry: entry)) {
                                PushNotificationRowView(entry: entry)
                            }
                            .listRowBackground(InspectorTheme.Colors.surface)
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
                                .tint(InspectorTheme.Colors.warning)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .contentMargins(.vertical, InspectorTheme.Spacing.sm)
            }
        }
        .inspectorBackground()
        .searchable(text: $searchText, prompt: "Title, body, category...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSimulator = true
                } label: {
                    Image(systemName: "play.circle")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(InspectorTheme.Colors.warning)
                }
            }
        }
        .sheet(isPresented: $showSimulator) {
            PushNotificationSimulatorView(store: store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(InspectorTheme.Colors.background)
        }
    }
}

// MARK: - Row

private struct PushNotificationRowView: View {
    let entry: PushNotificationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
            // Line 1: title
            Text(entry.displayTitle)
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(
                    entry.title != nil
                        ? InspectorTheme.Colors.textPrimary
                        : InspectorTheme.Colors.textTertiary
                )
                .lineLimit(1)

            // Line 2: body
            Text(entry.displayBody)
                .font(InspectorTheme.Typography.codeSmall)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)
                .lineLimit(2)

            // Line 3: badges + timestamp
            HStack(spacing: InspectorTheme.Spacing.sm) {
                if let badge = entry.badge {
                    Text("badge: \(badge)")
                        .font(InspectorTheme.Typography.detail)
                        .padding(.horizontal, InspectorTheme.Spacing.pip)
                        .padding(.vertical, InspectorTheme.Spacing.xxs)
                        .background(InspectorTheme.Colors.warning.opacity(InspectorTheme.Opacity.badge))
                        .foregroundStyle(InspectorTheme.Colors.warning)
                        .clipShape(.capsule)
                }

                if let category = entry.categoryIdentifier, !category.isEmpty {
                    Text(category)
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }

                Spacer()

                Text(entry.timestamp.relativeTimestamp)
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
        }
        .padding(.vertical, InspectorTheme.Spacing.xs)
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
        PushNotificationsView(store: InspectorStore())
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
