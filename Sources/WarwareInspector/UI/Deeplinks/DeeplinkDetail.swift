import SwiftUI

struct DeeplinkDetailView: View {
    let entry: DeeplinkEntry

    @State private var showCopied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                summaryHeader
                Divider().overlay(InspectorTheme.Colors.border)

                urlComponentsSection
                pathComponentsSection
                queryParametersSection
            }
            .padding(.horizontal, InspectorTheme.Spacing.lg)
        }
        .inspectorBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .overlay(alignment: .top) {
            if showCopied {
                copiedToast
            }
        }
        .animation(.easeInOut(duration: InspectorTheme.Animation.standard), value: showCopied)
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.md) {
            // Full URL (copyable)
            Text(entry.url)
                .font(InspectorTheme.Typography.codeSmall)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)
                .textSelection(.enabled)
                .lineLimit(4)

            // Timestamp
            Text(entry.timestamp.formatFullTimestamp())
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
        .padding(.vertical, InspectorTheme.Spacing.lg)
    }

    // MARK: - URL Components

    private var urlComponentsSection: some View {
        DetailSectionView(title: "URL Components") {
            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
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
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
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
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
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
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
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
            .font(InspectorTheme.Typography.detail)
            .fontWeight(.semibold)
            .foregroundStyle(InspectorTheme.Colors.success)
            .padding(.horizontal, InspectorTheme.Spacing.md)
            .padding(.vertical, InspectorTheme.Spacing.xs)
            .background(InspectorTheme.Colors.success.opacity(InspectorTheme.Opacity.badge))
            .clipShape(.capsule)
            .transition(.move(edge: .top).combined(with: .opacity))
            .padding(.top, InspectorTheme.Spacing.sm)
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
