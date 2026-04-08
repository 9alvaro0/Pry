import SwiftUI

/// Compares two network requests side by side, highlighting differences.
struct RequestDiffView: View {
    let left: NetworkEntry
    let right: NetworkEntry

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.lg) {
                    summaryDiff
                    statusDiff
                    timingDiff
                    headersDiff(title: "Request Headers", left: left.requestHeaders, right: right.requestHeaders)
                    bodyDiff(title: "Request Body", left: left.requestBody, right: right.requestBody)
                    headersDiff(title: "Response Headers", left: left.responseHeaders ?? [:], right: right.responseHeaders ?? [:])
                    bodyDiff(title: "Response Body", left: left.responseBody, right: right.responseBody)
                }
                .padding(.horizontal, InspectorTheme.Spacing.lg)
                .padding(.vertical, InspectorTheme.Spacing.md)
            }
            .inspectorBackground()
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(InspectorTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Summary

    private var summaryDiff: some View {
        VStack(spacing: 1) {
            diffEntryRow(entry: left, label: "A")
            diffEntryRow(entry: right, label: "B")
        }
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
    }

    private func diffEntryRow(entry: NetworkEntry, label: String) -> some View {
        HStack(spacing: InspectorTheme.Spacing.sm) {
            Text(label)
                .font(InspectorTheme.Typography.codeSmall)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(label == "A" ? InspectorTheme.Colors.accent : InspectorTheme.Colors.warning)
                .clipShape(.circle)

            Text(entry.requestMethod)
                .font(InspectorTheme.Typography.code)
                .fontWeight(.semibold)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)

            Text(entry.displayPath)
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            if let code = entry.responseStatusCode {
                Text("\(code)")
                    .inspectorStatusBadge(code)
            }

            if let d = entry.duration {
                Text(Optional(d).formattedDuration)
                    .font(InspectorTheme.Typography.codeSmall)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, InspectorTheme.Spacing.md)
        .padding(.vertical, InspectorTheme.Spacing.sm)
        .background(InspectorTheme.Colors.surface)
    }

    // MARK: - Status

    @ViewBuilder
    private var statusDiff: some View {
        let leftStatus = left.responseStatusCode
        let rightStatus = right.responseStatusCode
        if leftStatus != rightStatus {
            diffSection(title: "Status Code") {
                HStack(spacing: InspectorTheme.Spacing.xl) {
                    VStack(spacing: InspectorTheme.Spacing.xs) {
                        diffLabel("A")
                        if let s = leftStatus {
                            Text("\(s)").inspectorStatusBadge(s)
                        } else {
                            Text("--").font(InspectorTheme.Typography.code).foregroundStyle(InspectorTheme.Colors.textTertiary)
                        }
                    }
                    Image(systemName: "arrow.right")
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                    VStack(spacing: InspectorTheme.Spacing.xs) {
                        diffLabel("B")
                        if let s = rightStatus {
                            Text("\(s)").inspectorStatusBadge(s)
                        } else {
                            Text("--").font(InspectorTheme.Typography.code).foregroundStyle(InspectorTheme.Colors.textTertiary)
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Timing

    @ViewBuilder
    private var timingDiff: some View {
        if left.duration != right.duration {
            diffSection(title: "Duration") {
                HStack(spacing: InspectorTheme.Spacing.lg) {
                    timingPill("A", value: left.duration, color: InspectorTheme.Colors.accent)
                    timingPill("B", value: right.duration, color: InspectorTheme.Colors.warning)

                    Spacer()

                    if let ld = left.duration, let rd = right.duration {
                        let diff = rd - ld
                        let sign = diff >= 0 ? "+" : ""
                        Text("\(sign)\(String(format: "%.0fms", diff * 1000))")
                            .font(InspectorTheme.Typography.code)
                            .fontWeight(.semibold)
                            .foregroundStyle(diff > 0 ? InspectorTheme.Colors.error : InspectorTheme.Colors.success)
                    }
                }
            }
        }
    }

    private func timingPill(_ label: String, value: TimeInterval?, color: Color) -> some View {
        HStack(spacing: InspectorTheme.Spacing.xs) {
            diffLabel(label)
            Text(value.map { String(format: "%.0fms", $0 * 1000) } ?? "--")
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
        }
    }

    // MARK: - Headers Diff

    @ViewBuilder
    private func headersDiff(title: String, left: [String: String], right: [String: String]) -> some View {
        let allKeys = Set(left.keys).union(Set(right.keys)).sorted()
        let diffs = allKeys.compactMap { key -> HeaderDiff? in
            let lVal = left[key]
            let rVal = right[key]
            if lVal == rVal { return nil }
            return HeaderDiff(key: key, leftValue: lVal, rightValue: rVal)
        }

        if !diffs.isEmpty {
            diffSection(title: title) {
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
                    ForEach(diffs, id: \.key) { diff in
                        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                            Text(diff.key)
                                .font(InspectorTheme.Typography.detail)
                                .fontWeight(.semibold)
                                .foregroundStyle(InspectorTheme.Colors.textSecondary)

                            if let lv = diff.leftValue {
                                diffValueRow("A", value: lv, color: InspectorTheme.Colors.accent)
                            } else {
                                diffValueRow("A", value: "(missing)", color: InspectorTheme.Colors.textTertiary)
                            }

                            if let rv = diff.rightValue {
                                diffValueRow("B", value: rv, color: InspectorTheme.Colors.warning)
                            } else {
                                diffValueRow("B", value: "(missing)", color: InspectorTheme.Colors.textTertiary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Body Diff

    @ViewBuilder
    private func bodyDiff(title: String, left: String?, right: String?) -> some View {
        let l = left ?? ""
        let r = right ?? ""
        if l != r {
            diffSection(title: title) {
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
                    if !l.isEmpty {
                        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                            diffLabel("A")
                            CodeBlockView(text: l, language: .json)
                        }
                    }
                    if !r.isEmpty {
                        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                            diffLabel("B")
                            CodeBlockView(text: r, language: .json)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Shared Components

    private func diffSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)

            content()
                .padding(InspectorTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(InspectorTheme.Colors.surface)
                .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
        }
    }

    private func diffLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 18, height: 18)
            .background(text == "A" ? InspectorTheme.Colors.accent : InspectorTheme.Colors.warning)
            .clipShape(.circle)
    }

    private func diffValueRow(_ label: String, value: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: InspectorTheme.Spacing.xs) {
            diffLabel(label)
            Text(value)
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(color == InspectorTheme.Colors.textTertiary ? color : InspectorTheme.Colors.textPrimary)
                .lineLimit(3)
        }
    }
}

// MARK: - Helper Model

private struct HeaderDiff {
    let key: String
    let leftValue: String?
    let rightValue: String?
}

// MARK: - Previews

#if DEBUG
#Preview("Diff - Different Status") {
    RequestDiffView(left: .mockSuccess, right: .mockError)
}

#Preview("Diff - GraphQL") {
    RequestDiffView(left: .mockGraphQLQuery, right: .mockGraphQLError)
}
#endif
