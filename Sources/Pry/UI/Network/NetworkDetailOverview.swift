import SwiftUI

/// Overview tab: timing breakdown, redirect chain, GraphQL info, JWT token.
struct NetworkDetailOverview: View {
    let entry: NetworkEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            graphQLSection
            timingSection
            redirectChainSection
            jwtSection
        }
    }

    // MARK: - GraphQL

    @ViewBuilder
    private var graphQLSection: some View {
        if let gql = entry.graphQLInfo {
            DetailSectionView(title: "GraphQL", collapsible: false) {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.md) {
                    HStack(spacing: PryTheme.Spacing.sm) {
                        Text(gql.operationType.rawValue)
                            .font(PryTheme.Typography.code)
                            .fontWeight(.bold)
                            .foregroundStyle(gql.operationType.color)
                            .padding(.horizontal, PryTheme.Spacing.sm)
                            .padding(.vertical, PryTheme.Spacing.xxs)
                            .background(gql.operationType.color.opacity(PryTheme.Opacity.badge))
                            .clipShape(.capsule)

                        if let name = gql.operationName {
                            Text(name)
                                .font(PryTheme.Typography.code)
                                .fontWeight(.semibold)
                                .foregroundStyle(PryTheme.Colors.textPrimary)
                        } else {
                            Text("Anonymous")
                                .font(PryTheme.Typography.code)
                                .foregroundStyle(PryTheme.Colors.textTertiary)
                                .italic()
                        }
                    }

                    if gql.hasErrors {
                        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                            ForEach(Array(gql.errors.enumerated()), id: \.offset) { _, error in
                                HStack(alignment: .top, spacing: PryTheme.Spacing.xs) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(PryTheme.Typography.sectionLabel)
                                        .foregroundStyle(PryTheme.Colors.error)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(error.message)
                                            .font(PryTheme.Typography.code)
                                            .foregroundStyle(PryTheme.Colors.error)
                                        if let path = error.path {
                                            Text(path)
                                                .font(PryTheme.Typography.detail)
                                                .foregroundStyle(PryTheme.Colors.textTertiary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(PryTheme.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PryTheme.Colors.error.opacity(PryTheme.Opacity.faint))
                        .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))
                    }

                    CodeBlockView(text: gql.query, language: .text)

                    if let variables = gql.variables {
                        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                            Text("VARIABLES")
                                .font(PryTheme.Typography.sectionLabel)
                                .tracking(PryTheme.Text.tracking)
                                .foregroundStyle(PryTheme.Colors.textTertiary)
                            CodeBlockView(text: variables, language: .json)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Timing

    @ViewBuilder
    private var timingSection: some View {
        if let metrics = entry.metrics {
            DetailSectionView(title: "Timing Breakdown", collapsible: true) {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                    timingRow("DNS Lookup", value: metrics.dnsLookup)
                    timingRow("TCP Connect", value: metrics.tcpConnect)
                    timingRow("TLS Handshake", value: metrics.tlsHandshake)
                    timingRow("Request Sent", value: metrics.requestSent)
                    timingRow("Waiting (TTFB)", value: metrics.waitingForResponse)
                    timingRow("Response Received", value: metrics.responseReceived)
                }
            }
        }
    }

    private func timingRow(_ label: String, value: TimeInterval?) -> some View {
        HStack {
            Text(label)
                .font(PryTheme.Typography.body)
                .foregroundStyle(PryTheme.Colors.textSecondary)
            Spacer()
            Text(value.map { String(format: "%.1fms", $0 * 1000) } ?? "-")
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
        }
    }

    // MARK: - Redirect Chain

    @ViewBuilder
    private var redirectChainSection: some View {
        if !entry.redirects.isEmpty {
            DetailSectionView(title: "Redirect Chain", collapsible: true) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entry.redirects.enumerated()), id: \.element.id) { index, hop in
                        redirectHopRow(statusCode: hop.statusCode, url: hop.fromURL)
                        redirectConnector
                        if index == entry.redirects.count - 1 {
                            redirectHopRow(
                                statusCode: entry.responseStatusCode ?? 0,
                                url: hop.toURL,
                                isFinal: true
                            )
                        }
                    }
                }
            }
        }
    }

    private func redirectHopRow(statusCode: Int, url: String, isFinal: Bool = false) -> some View {
        HStack(alignment: .center, spacing: PryTheme.Spacing.sm) {
            Text("\(statusCode)")
                .pryStatusBadge(statusCode)
            Text(url)
                .font(PryTheme.Typography.codeSmall)
                .foregroundStyle(isFinal ? PryTheme.Colors.textPrimary : PryTheme.Colors.textSecondary)
                .lineLimit(2)
                .truncationMode(.middle)
                .textSelection(.enabled)
            Spacer(minLength: 0)
            CopyButtonView(valueToCopy: url)
        }
        .padding(.vertical, PryTheme.Spacing.xs)
    }

    private var redirectConnector: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(PryTheme.Colors.border)
                .frame(width: 1, height: 14)
                .padding(.leading, 18)
            Spacer()
        }
    }

    // MARK: - JWT

    @ViewBuilder
    private var jwtSection: some View {
        let token = entry.authToken ?? entry.requestHeaders["Authorization"]
        if let token, JWTDecoder.decode(token) != nil {
            DetailSectionView(title: "JWT Token", collapsible: true) {
                JWTDetailView(token: token)
            }
        }
    }
}
