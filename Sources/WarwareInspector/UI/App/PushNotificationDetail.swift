import SwiftUI

struct PushNotificationDetailView: View {
    let entry: PushNotificationEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                summaryHeader
                Divider().overlay(InspectorTheme.Colors.border)

                notificationSection
                userInfoSection
            }
            .padding(.horizontal, InspectorTheme.Spacing.lg)
        }
        .inspectorBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.md) {
            Text(entry.displayTitle)
                .font(InspectorTheme.Typography.heading)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)

            Text(entry.displayBody)
                .font(InspectorTheme.Typography.codeSmall)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)
                .textSelection(.enabled)

            Text(entry.timestamp.formatFullTimestamp())
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
        .padding(.vertical, InspectorTheme.Spacing.lg)
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        DetailSectionView(title: "Notification") {
            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                if let title = entry.title {
                    DetailRowView(label: "Title", value: title)
                }
                if let subtitle = entry.subtitle {
                    DetailRowView(label: "Subtitle", value: subtitle)
                }
                if let body = entry.body {
                    DetailRowView(label: "Body", value: body)
                }
                if let badge = entry.badge {
                    DetailRowView(label: "Badge", value: "\(badge)")
                }
                if let sound = entry.sound {
                    DetailRowView(label: "Sound", value: sound)
                }
                if let category = entry.categoryIdentifier {
                    DetailRowView(label: "Category", value: category)
                }
                if let thread = entry.threadIdentifier {
                    DetailRowView(label: "Thread", value: thread)
                }
            }
        }
    }

    // MARK: - User Info Section

    @ViewBuilder
    private var userInfoSection: some View {
        if !entry.userInfo.isEmpty {
            DetailSectionView(
                title: "User Info (\(entry.userInfo.count))",
                collapsible: true
            ) {
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
                    ForEach(entry.userInfo.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        DetailRowView(label: key, value: value)
                    }
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(entry.displayTitle)
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        ToolbarItem(placement: .topBarTrailing) {
            CopyButtonView(valueToCopy: [entry.title, entry.body].compactMap { $0 }.joined(separator: "\n"))
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Detail - Promo") {
    NavigationStack {
        PushNotificationDetailView(entry: .mockPromo)
    }
}

#Preview("Detail - Chat") {
    NavigationStack {
        PushNotificationDetailView(entry: .mockChat)
    }
}

#Preview("Detail - Silent") {
    NavigationStack {
        PushNotificationDetailView(entry: .mockSilent)
    }
}
#endif
