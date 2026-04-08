import SwiftUI

struct PushNotificationDetailView: View {
    let entry: PushNotificationEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                summaryHeader
                Divider().overlay(PryTheme.Colors.border)

                notificationSection
                userInfoSection
                rawPayloadSection
            }
            .padding(.horizontal, PryTheme.Spacing.lg)
        }
        .pryBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.md) {
            Text(entry.displayTitle)
                .font(PryTheme.Typography.heading)
                .foregroundStyle(PryTheme.Colors.textPrimary)

            Text(entry.displayBody)
                .font(PryTheme.Typography.codeSmall)
                .foregroundStyle(PryTheme.Colors.textSecondary)
                .textSelection(.enabled)

            Text(entry.timestamp.formatFullTimestamp())
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
        .padding(.vertical, PryTheme.Spacing.lg)
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        DetailSectionView(title: "Notification") {
            VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
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
                VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                    ForEach(entry.userInfo.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        DetailRowView(label: key, value: value)
                    }
                }
            }
        }
    }

    // MARK: - Raw APNs Payload

    @ViewBuilder
    private var rawPayloadSection: some View {
        if let payload = entry.rawPayload, !payload.isEmpty {
            DetailSectionView(title: "APNs Payload", collapsible: true) {
                CodeBlockView(text: payload, language: .json)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(entry.displayTitle)
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
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
