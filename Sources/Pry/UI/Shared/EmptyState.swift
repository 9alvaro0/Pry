import SwiftUI

@_spi(PryPro) public struct EmptyStateView: View {
    @_spi(PryPro) public let title: String
    @_spi(PryPro) public let systemImage: String
    @_spi(PryPro) public let description: String

    @_spi(PryPro) public var body: some View {
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
