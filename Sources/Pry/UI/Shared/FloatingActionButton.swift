import SwiftUI

package struct FloatingActionButtonView: View {
    package let icon: String
    package let backgroundColor: Color
    package let foregroundColor: Color
    package let size: CGFloat
    package let action: () -> Void

    package var body: some View {
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
