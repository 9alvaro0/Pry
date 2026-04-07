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
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}
