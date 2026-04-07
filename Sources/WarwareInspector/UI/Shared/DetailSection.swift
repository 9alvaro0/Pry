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
