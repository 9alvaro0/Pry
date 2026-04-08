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
                VStack(alignment: .leading, spacing: InspectorTheme.Spacing.lg) {
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

    // MARK: - Summary Cards

    private var summaryCards: some View {
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
                .frame(width: InspectorTheme.Size.diffLabel, height: InspectorTheme.Size.diffLabel)
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
                Text(d.formattedDuration)
                    .font(InspectorTheme.Typography.codeSmall)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, InspectorTheme.Spacing.md)
        .padding(.vertical, InspectorTheme.Spacing.sm)
        .background(InspectorTheme.Colors.surface)
    }

    // MARK: - Diff Summary Banner

    private var diffSummaryBanner: some View {
        HStack(spacing: InspectorTheme.Spacing.sm) {
            Image(systemName: totalDifferences > 0 ? "exclamationmark.triangle" : "checkmark.circle")
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(totalDifferences > 0 ? InspectorTheme.Colors.warning : InspectorTheme.Colors.success)

            Text(totalDifferences > 0
                 ? "\(totalDifferences) difference\(totalDifferences == 1 ? "" : "s") found"
                 : "Requests are identical"
            )
            .font(InspectorTheme.Typography.body)
            .fontWeight(.medium)
            .foregroundStyle(InspectorTheme.Colors.textPrimary)

            Spacer()
        }
        .padding(InspectorTheme.Spacing.md)
        .background(
            (totalDifferences > 0 ? InspectorTheme.Colors.warning : InspectorTheme.Colors.success).opacity(InspectorTheme.Opacity.border)
        )
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
    }

    // MARK: - Identical Row

    private func identicalRow(_ title: String) -> some View {
        HStack(spacing: InspectorTheme.Spacing.sm) {
            Image(systemName: "checkmark")
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.success)

            Text(title)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)

            Spacer()

            Text("Identical")
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
        .padding(.horizontal, InspectorTheme.Spacing.md)
        .padding(.vertical, InspectorTheme.Spacing.sm)
    }

    // MARK: - Status Diff

    private var statusDiffSection: some View {
        diffSection(title: "Status Code") {
            HStack(spacing: InspectorTheme.Spacing.xl) {
                VStack(spacing: InspectorTheme.Spacing.xs) {
                    diffLabel("A")
                    if let s = left.responseStatusCode {
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
                    if let s = right.responseStatusCode {
                        Text("\(s)").inspectorStatusBadge(s)
                    } else {
                        Text("--").font(InspectorTheme.Typography.code).foregroundStyle(InspectorTheme.Colors.textTertiary)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Timing Diff

    private var timingDiffSection: some View {
        diffSection(title: "Duration") {
            HStack(spacing: InspectorTheme.Spacing.lg) {
                timingPill("A", value: left.duration)
                timingPill("B", value: right.duration)

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

    private func timingPill(_ label: String, value: TimeInterval?) -> some View {
        HStack(spacing: InspectorTheme.Spacing.xs) {
            diffLabel(label)
            Text(value.map { String(format: "%.0fms", $0 * 1000) } ?? "--")
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
        }
    }

    // MARK: - Headers Diff

    private func headersDiffSection(title: String, diffs: [HeaderDiff]) -> some View {
        diffSection(title: title) {
            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
                ForEach(diffs, id: \.key) { diff in
                    VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                        Text(diff.key)
                            .font(InspectorTheme.Typography.detail)
                            .fontWeight(.semibold)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)

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
            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
                if let l = left, !l.isEmpty {
                    VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                        diffLabel("A")
                        CodeBlockView(text: l, language: .json)
                    }
                }
                if let r = right, !r.isEmpty {
                    VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                        diffLabel("B")
                        CodeBlockView(text: r, language: .json)
                    }
                }
            }
        }
    }

    // MARK: - Shared Components

    private func diffSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(InspectorTheme.Typography.sectionLabel)
                .tracking(InspectorTheme.Text.tracking)
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
            .font(.system(size: InspectorTheme.FontSize.smallIcon, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: InspectorTheme.Size.diffLabelSmall, height: InspectorTheme.Size.diffLabelSmall)
            .background(text == "A" ? InspectorTheme.Colors.accent : InspectorTheme.Colors.warning)
            .clipShape(.circle)
    }

    private func diffValueRow(_ label: String, value: String, isMissing: Bool) -> some View {
        HStack(alignment: .top, spacing: InspectorTheme.Spacing.xs) {
            diffLabel(label)
            Text(value)
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(isMissing ? InspectorTheme.Colors.textTertiary : InspectorTheme.Colors.textPrimary)
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
