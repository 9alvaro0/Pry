import SwiftUI

struct DetailSectionView<Content: View>: View {
    let title: String
    var collapsible: Bool = false
    var startCollapsed: Bool = false
    @ViewBuilder let content: () -> Content

    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                if collapsible {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
            } label: {
                HStack {
                    Text(title)
                        .font(InspectorTheme.Typography.detail)
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundStyle(InspectorTheme.Colors.textSecondary)

                    Spacer()

                    if collapsible {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(InspectorTheme.Typography.detail)
                            .foregroundStyle(InspectorTheme.Colors.textSecondary)
                    }
                }
                .padding(.vertical, InspectorTheme.Spacing.sm)
            }
            .buttonStyle(.plain)
            .disabled(!collapsible)

            // Content
            if isExpanded {
                content()
                    .padding(.bottom, InspectorTheme.Spacing.sm)
            }
        }
        .onAppear {
            if startCollapsed { isExpanded = false }
        }
    }
}

#if DEBUG
#Preview("Static Section") {
    DetailSectionView(title: "Request Details") {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
            DetailRowView(label: "Host", value: "api.example.com")
            DetailRowView(label: "Path", value: "/v1/users")
        }
    }
    .padding()
    .inspectorBackground()
}

#Preview("Collapsible - Expanded") {
    DetailSectionView(title: "Headers", collapsible: true) {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
            DetailRowView(label: "Content-Type", value: "application/json")
            DetailRowView(label: "Authorization", value: "Bearer ***")
        }
    }
    .padding()
    .inspectorBackground()
}

#Preview("Collapsible - Collapsed") {
    DetailSectionView(title: "Response Headers", collapsible: true, startCollapsed: true) {
        DetailRowView(label: "Content-Type", value: "application/json")
    }
    .padding()
    .inspectorBackground()
}
#endif
