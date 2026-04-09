import SwiftUI

/// Compares two network requests side by side, highlighting differences.
struct RequestDiffView: View {
    let left: NetworkEntry
    let right: NetworkEntry

    @Environment(\.dismiss) private var dismiss

    // MARK: - Diff Computation

    private var statusChanged: Bool { left.responseStatusCode != right.responseStatusCode }
    private var durationChanged: Bool { left.duration != right.duration }

    private var requestHeaderDiffs: [HeaderDiff] {
        computeHeaderDiffs(left: left.requestHeaders, right: right.requestHeaders)
    }

    private var responseHeaderDiffs: [HeaderDiff] {
        computeHeaderDiffs(left: left.responseHeaders ?? [:], right: right.responseHeaders ?? [:])
    }

    private var requestBodyChanged: Bool { (left.requestBody ?? "") != (right.requestBody ?? "") }
    private var responseBodyChanged: Bool { (left.responseBody ?? "") != (right.responseBody ?? "") }

    private var totalDifferences: Int {
        var count = 0
        if statusChanged { count += 1 }
        if durationChanged { count += 1 }
        if !requestHeaderDiffs.isEmpty { count += 1 }
        if !responseHeaderDiffs.isEmpty { count += 1 }
        if requestBodyChanged { count += 1 }
        if responseBodyChanged { count += 1 }
        return count
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PryTheme.Spacing.lg) {
                    summaryCards
                    diffSummaryBanner

                    // Status
                    if statusChanged {
                        statusDiffSection
                    } else {
                        identicalRow("Status Code")
                    }

                    // Duration
                    if durationChanged {
                        timingDiffSection
                    } else {
                        identicalRow("Duration")
                    }

                    // Request Headers
                    if !requestHeaderDiffs.isEmpty {
                        headersDiffSection(title: "Request Headers", diffs: requestHeaderDiffs)
                    } else {
                        identicalRow("Request Headers")
                    }

                    // Request Body
                    if requestBodyChanged {
                        bodyDiffSection(title: "Request Body", left: left.requestBody, right: right.requestBody)
                    } else {
                        identicalRow("Request Body")
                    }

                    // Response Headers
                    if !responseHeaderDiffs.isEmpty {
                        headersDiffSection(title: "Response Headers", diffs: responseHeaderDiffs)
                    } else {
                        identicalRow("Response Headers")
                    }

                    // Response Body
                    if responseBodyChanged {
                        bodyDiffSection(title: "Response Body", left: left.responseBody, right: right.responseBody)
                    } else {
                        identicalRow("Response Body")
                    }
                }
                .padding(.horizontal, PryTheme.Spacing.lg)
                .padding(.vertical, PryTheme.Spacing.md)
            }
            .pryBackground()
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(PryTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(PryTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        VStack(spacing: 1) {
            diffEntryRow(entry: left, label: "A")
            diffEntryRow(entry: right, label: "B")
        }
        .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
    }

    private func diffEntryRow(entry: NetworkEntry, label: String) -> some View {
        HStack(spacing: PryTheme.Spacing.sm) {
            Text(label)
                .font(PryTheme.Typography.codeSmall)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: PryTheme.Size.diffLabel, height: PryTheme.Size.diffLabel)
                .background(label == "A" ? PryTheme.Colors.accent : PryTheme.Colors.warning)
                .clipShape(.circle)

            Text(entry.requestMethod)
                .font(PryTheme.Typography.code)
                .fontWeight(.semibold)
                .foregroundStyle(PryTheme.Colors.textSecondary)

            Text(entry.displayPath)
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            if let code = entry.responseStatusCode {
                Text("\(code)")
                    .pryStatusBadge(code)
            }

            if let d = entry.duration {
                Text(d.formattedDuration)
                    .font(PryTheme.Typography.codeSmall)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, PryTheme.Spacing.md)
        .padding(.vertical, PryTheme.Spacing.sm)
        .background(PryTheme.Colors.surface)
    }

    // MARK: - Diff Summary Banner

    private var diffSummaryBanner: some View {
        HStack(spacing: PryTheme.Spacing.sm) {
            Image(systemName: totalDifferences > 0 ? "exclamationmark.triangle" : "checkmark.circle")
                .font(PryTheme.Typography.body)
                .foregroundStyle(totalDifferences > 0 ? PryTheme.Colors.warning : PryTheme.Colors.success)

            Text(totalDifferences > 0
                 ? "\(totalDifferences) difference\(totalDifferences == 1 ? "" : "s") found"
                 : "Requests are identical"
            )
            .font(PryTheme.Typography.body)
            .fontWeight(.medium)
            .foregroundStyle(PryTheme.Colors.textPrimary)

            Spacer()
        }
        .padding(PryTheme.Spacing.md)
        .background(
            (totalDifferences > 0 ? PryTheme.Colors.warning : PryTheme.Colors.success).opacity(PryTheme.Opacity.border)
        )
        .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
    }

    // MARK: - Identical Row

    private func identicalRow(_ title: String) -> some View {
        HStack(spacing: PryTheme.Spacing.sm) {
            Image(systemName: "checkmark")
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.success)

            Text(title)
                .font(PryTheme.Typography.body)
                .foregroundStyle(PryTheme.Colors.textTertiary)

            Spacer()

            Text("Identical")
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
        .padding(.horizontal, PryTheme.Spacing.md)
        .padding(.vertical, PryTheme.Spacing.sm)
    }

    // MARK: - Status Diff

    private var statusDiffSection: some View {
        diffSection(title: "Status Code") {
            HStack(spacing: PryTheme.Spacing.xl) {
                VStack(spacing: PryTheme.Spacing.xs) {
                    diffLabel("A")
                    if let s = left.responseStatusCode {
                        Text("\(s)").pryStatusBadge(s)
                    } else {
                        Text("--").font(PryTheme.Typography.code).foregroundStyle(PryTheme.Colors.textTertiary)
                    }
                }
                Image(systemName: "arrow.right")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
                VStack(spacing: PryTheme.Spacing.xs) {
                    diffLabel("B")
                    if let s = right.responseStatusCode {
                        Text("\(s)").pryStatusBadge(s)
                    } else {
                        Text("--").font(PryTheme.Typography.code).foregroundStyle(PryTheme.Colors.textTertiary)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Timing Diff

    private var timingDiffSection: some View {
        diffSection(title: "Duration") {
            HStack(spacing: PryTheme.Spacing.lg) {
                timingPill("A", value: left.duration)
                timingPill("B", value: right.duration)

                Spacer()

                if let ld = left.duration, let rd = right.duration {
                    let diff = rd - ld
                    let sign = diff >= 0 ? "+" : ""
                    Text("\(sign)\(String(format: "%.0fms", diff * 1000))")
                        .font(PryTheme.Typography.code)
                        .fontWeight(.semibold)
                        .foregroundStyle(diff > 0 ? PryTheme.Colors.error : PryTheme.Colors.success)
                }
            }
        }
    }

    private func timingPill(_ label: String, value: TimeInterval?) -> some View {
        HStack(spacing: PryTheme.Spacing.xs) {
            diffLabel(label)
            Text(value.map { String(format: "%.0fms", $0 * 1000) } ?? "--")
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
        }
    }

    // MARK: - Headers Diff

    private func headersDiffSection(title: String, diffs: [HeaderDiff]) -> some View {
        diffSection(title: title) {
            VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                ForEach(diffs, id: \.key) { diff in
                    VStack(alignment: .leading, spacing: PryTheme.Spacing.xxs) {
                        Text(diff.key)
                            .font(PryTheme.Typography.detail)
                            .fontWeight(.semibold)
                            .foregroundStyle(PryTheme.Colors.textSecondary)

                        diffValueRow("A", value: diff.leftValue ?? "(missing)", isMissing: diff.leftValue == nil)
                        diffValueRow("B", value: diff.rightValue ?? "(missing)", isMissing: diff.rightValue == nil)
                    }
                }
            }
        }
    }

    // MARK: - Body Diff

    private func bodyDiffSection(title: String, left: String?, right: String?) -> some View {
        diffSection(title: title) {
            VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                if let l = left, !l.isEmpty {
                    VStack(alignment: .leading, spacing: PryTheme.Spacing.xxs) {
                        diffLabel("A")
                        CodeBlockView(text: l, language: .json)
                    }
                }
                if let r = right, !r.isEmpty {
                    VStack(alignment: .leading, spacing: PryTheme.Spacing.xxs) {
                        diffLabel("B")
                        CodeBlockView(text: r, language: .json)
                    }
                }
            }
        }
    }

    // MARK: - Shared Components

    private func diffSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(PryTheme.Typography.sectionLabel)
                .tracking(PryTheme.Text.tracking)
                .foregroundStyle(PryTheme.Colors.textTertiary)

            content()
                .padding(PryTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PryTheme.Colors.surface)
                .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
        }
    }

    private func diffLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: PryTheme.FontSize.smallIcon, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: PryTheme.Size.diffLabelSmall, height: PryTheme.Size.diffLabelSmall)
            .background(text == "A" ? PryTheme.Colors.accent : PryTheme.Colors.warning)
            .clipShape(.circle)
    }

    private func diffValueRow(_ label: String, value: String, isMissing: Bool) -> some View {
        HStack(alignment: .top, spacing: PryTheme.Spacing.xs) {
            diffLabel(label)
            Text(value)
                .font(PryTheme.Typography.code)
                .foregroundStyle(isMissing ? PryTheme.Colors.textTertiary : PryTheme.Colors.textPrimary)
                .lineLimit(3)
        }
    }

    // MARK: - Helpers

    private func computeHeaderDiffs(left: [String: String], right: [String: String]) -> [HeaderDiff] {
        Set(left.keys).union(Set(right.keys)).sorted().compactMap { key in
            let lVal = left[key]
            let rVal = right[key]
            guard lVal != rVal else { return nil }
            return HeaderDiff(key: key, leftValue: lVal, rightValue: rVal)
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

#Preview("Diff - Same Request") {
    RequestDiffView(left: .mockSuccess, right: .mockSuccess)
}
#endif
