import SwiftUI

struct PlainTextViewerView: View {
    let text: String

    @State private var isExpanded = false

    private var shouldShowExpandButton: Bool {
        text.components(separatedBy: .newlines).count > 8
    }

    private var displayText: String {
        guard !isExpanded else { return text }
        let lines = text.split(whereSeparator: \.isNewline)
        guard lines.count > 8 else { return text }
        return lines.prefix(8).joined(separator: "\n") + "\n..."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
            if shouldShowExpandButton {
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    HStack(spacing: InspectorTheme.Spacing.xs) {
                        Text(isExpanded ? "Collapse" : "Show More")
                            .font(InspectorTheme.Typography.detail)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(InspectorTheme.Typography.detail)
                    }
                    .foregroundStyle(InspectorTheme.Colors.accent)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Text(displayText)
                .font(.system(.body, design: .default))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .lineLimit(isExpanded ? nil : 8)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
        }
        .inspectorCodeBlock()
    }
}
