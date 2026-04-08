import SwiftUI

struct DeeplinkDetailView: View {
    let entry: DeeplinkEntry

    @State private var showCopied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                summaryHeader
                Divider().overlay(PryTheme.Colors.border)

                urlComponentsSection
                pathComponentsSection
                queryParametersSection
            }
            .padding(.horizontal, PryTheme.Spacing.lg)
        }
        .pryBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .overlay(alignment: .top) {
            if showCopied {
                copiedToast
            }
        }
        .animation(.easeInOut(duration: PryTheme.Animation.standard), value: showCopied)
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.md) {
            // Full URL (copyable)
            Text(entry.url)
                .font(PryTheme.Typography.codeSmall)
                .foregroundStyle(PryTheme.Colors.textSecondary)
                .textSelection(.enabled)
                .lineLimit(4)

            // Timestamp
            Text(entry.timestamp.formatFullTimestamp())
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
        .padding(.vertical, PryTheme.Spacing.lg)
    }

    // MARK: - URL Components

    private var urlComponentsSection: some View {
        DetailSectionView(title: "URL Components") {
            VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                if let scheme = entry.scheme {
                    DetailRowView(label: "Scheme", value: scheme)
                }
                if let host = entry.host {
                    DetailRowView(label: "Host", value: host)
                }
                DetailRowView(label: "Path", value: entry.path)
                if let fragment = entry.fragment {
                    DetailRowView(label: "Fragment", value: fragment)
                }
            }
        }
    }

    // MARK: - Path Components

    @ViewBuilder
    private var pathComponentsSection: some View {
        if !entry.pathComponents.isEmpty {
            DetailSectionView(title: "Path Components", collapsible: true) {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                    ForEach(Array(entry.pathComponents.enumerated()), id: \.offset) { index, component in
                        DetailRowView(label: "[\(index)]", value: component)
                    }
                }
            }
        }
    }

    // MARK: - Query Parameters

    @ViewBuilder
    private var queryParametersSection: some View {
        if !entry.queryParameters.isEmpty {
            DetailSectionView(title: "Query Parameters (\(entry.queryParameters.count))", collapsible: true) {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                    ForEach(entry.queryParameters) { param in
                        DetailRowView(label: param.name, value: param.value ?? "nil")
                    }
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(entry.schemeAndHost)
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        ToolbarItem(placement: .topBarTrailing) {
            CopyButtonView(valueToCopy: entry.url)
        }
    }

    // MARK: - Copied Toast

    private var copiedToast: some View {
        Text("Copied!")
            .font(PryTheme.Typography.detail)
            .fontWeight(.semibold)
            .foregroundStyle(PryTheme.Colors.success)
            .padding(.horizontal, PryTheme.Spacing.md)
            .padding(.vertical, PryTheme.Spacing.xs)
            .background(PryTheme.Colors.success.opacity(PryTheme.Opacity.badge))
            .clipShape(.capsule)
            .transition(.move(edge: .top).combined(with: .opacity))
            .padding(.top, PryTheme.Spacing.sm)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Detail - Custom Scheme") {
    NavigationStack {
        DeeplinkDetailView(entry: .mockCustomScheme)
    }
}

#Preview("Detail - Universal Link") {
    NavigationStack {
        DeeplinkDetailView(entry: .mockUniversalLink)
    }
}

#Preview("Detail - Widget Link") {
    NavigationStack {
        DeeplinkDetailView(entry: .mockWidgetLink)
    }
}
#endif
