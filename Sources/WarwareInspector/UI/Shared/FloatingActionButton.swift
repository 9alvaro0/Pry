import SwiftUI

struct FloatingActionButtonView: View {
    let icon: String
    let backgroundColor: Color
    let foregroundColor: Color
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(.circle)
                .shadow(color: .black.opacity(InspectorTheme.Shadow.opacity), radius: InspectorTheme.Shadow.radius, x: InspectorTheme.Shadow.offsetX, y: InspectorTheme.Shadow.offsetY)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("FAB") {
    ZStack {
        Color(InspectorTheme.Colors.background)
            .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButtonView(
                    icon: "ladybug.fill",
                    backgroundColor: InspectorTheme.Colors.fab,
                    foregroundColor: InspectorTheme.Colors.fabForeground,
                    size: InspectorTheme.Size.fab
                ) {}
                .padding()
            }
        }
    }
}
#endif
