import SwiftUI

@_spi(PryPro) public struct FloatingActionButtonView: View {
    @_spi(PryPro) public let icon: String
    @_spi(PryPro) public let backgroundColor: Color
    @_spi(PryPro) public let foregroundColor: Color
    @_spi(PryPro) public let size: CGFloat
    @_spi(PryPro) public var glowColor: Color? = nil
    @_spi(PryPro) public let action: () -> Void

    @_spi(PryPro) public var body: some View {
        Button(action: action) {
            Image("pry-icon", bundle: .module)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(foregroundColor)
                .frame(width: size * 0.85, height: size * 0.85)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(.circle)
                .shadow(color: .black.opacity(PryTheme.Shadow.opacity), radius: PryTheme.Shadow.radius, x: PryTheme.Shadow.offsetX, y: PryTheme.Shadow.offsetY)
        }
        .buttonStyle(.plain)
        .overlay {
            if let glowColor {
                Circle()
                    .stroke(glowColor.opacity(0.5), lineWidth: 2)
                    .frame(width: size + 4, height: size + 4)
                    .shadow(color: glowColor.opacity(0.4), radius: 12)
            }
        }
    }
}

#if DEBUG
#Preview("FAB") {
    ZStack {
        Color(PryTheme.Colors.background)
            .ignoresSafeArea()

        FloatingActionButtonView(
            icon: "",
            backgroundColor: PryTheme.Colors.fab,
            foregroundColor: PryTheme.Colors.fabForeground,
            size: PryTheme.Size.fab
        ) {}
    }
}
#endif
