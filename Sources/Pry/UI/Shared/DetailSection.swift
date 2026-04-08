import SwiftUI

struct DetailSectionView<Content: View>: View {
    let title: String
    var collapsible: Bool = false
    var startCollapsed: Bool = false
    @ViewBuilder let content: () -> Content

    @State private var isExpanded: Bool

    init(title: String, collapsible: Bool = false, startCollapsed: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.collapsible = collapsible
        self.startCollapsed = startCollapsed
        self.content = content
        self._isExpanded = State(initialValue: !startCollapsed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            if collapsible {
                Button {
                    withAnimation(.easeInOut(duration: PryTheme.Animation.standard)) {
                        isExpanded.toggle()
                    }
                } label: {
                    sectionHeader
                }
                .buttonStyle(.plain)
            } else {
                sectionHeader
            }

            // Content
            if isExpanded {
                content()
                    .padding(.bottom, PryTheme.Spacing.sm)
            }
        }
    }

    private var sectionHeader: some View {
        HStack {
            Text(title)
                .font(PryTheme.Typography.detail)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .tracking(PryTheme.Text.tracking)
                .foregroundStyle(PryTheme.Colors.textSecondary)

            Spacer()

            if collapsible {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, PryTheme.Spacing.sm)
        .contentShape(.rect)
    }
}

#if DEBUG
#Preview("Static Section") {
    DetailSectionView(title: "Request Details") {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            DetailRowView(label: "Host", value: "api.example.com")
            DetailRowView(label: "Path", value: "/v1/users")
        }
    }
    .padding()
    .pryBackground()
}

#Preview("Collapsible - Expanded") {
    DetailSectionView(title: "Headers", collapsible: true) {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            DetailRowView(label: "Content-Type", value: "application/json")
            DetailRowView(label: "Authorization", value: "Bearer ***")
        }
    }
    .padding()
    .pryBackground()
}

#Preview("Collapsible - Collapsed") {
    DetailSectionView(title: "Response Headers", collapsible: true, startCollapsed: true) {
        DetailRowView(label: "Content-Type", value: "application/json")
    }
    .padding()
    .pryBackground()
}
#endif
