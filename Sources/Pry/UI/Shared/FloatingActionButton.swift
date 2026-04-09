import SwiftUI

@_spi(PryPro) public struct FloatingActionButtonView: View {
    @_spi(PryPro) public let icon: String
    @_spi(PryPro) public let backgroundColor: Color
    @_spi(PryPro) public let foregroundColor: Color
    @_spi(PryPro) public let size: CGFloat
    @_spi(PryPro) public let action: () -> Void

    @_spi(PryPro) public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(.circle)
                .shadow(color: .black.opacity(PryTheme.Shadow.opacity), radius: PryTheme.Shadow.radius, x: PryTheme.Shadow.offsetX, y: PryTheme.Shadow.offsetY)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("FAB") {
    ZStack {
        Color(PryTheme.Colors.background)
            .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButtonView(
                    icon: "ladybug.fill",
                    backgroundColor: PryTheme.Colors.fab,
                    foregroundColor: PryTheme.Colors.fabForeground,
                    size: PryTheme.Size.fab
                ) {}
                .padding()
            }
        }
    }
}
#endif
