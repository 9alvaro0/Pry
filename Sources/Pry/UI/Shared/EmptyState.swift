import SwiftUI

package struct EmptyStateView: View {
    package let title: String
    package let systemImage: String
    package let description: String

    package var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview("Network Empty") {
    EmptyStateView(
        title: "No network requests",
        systemImage: "network",
        description: "Network requests will appear here as you use the app"
    )
    .pryBackground()
}

#Preview("Console Empty") {
    EmptyStateView(
        title: "No console logs",
        systemImage: "text.alignleft",
        description: "Print statements will appear here as the app runs"
    )
    .pryBackground()
}
#endif
