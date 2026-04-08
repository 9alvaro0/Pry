import Foundation
import SwiftUI

extension Int {

    func formatBytes() -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(self))
    }

    func statusTextColor() -> Color {
        PryTheme.Colors.statusForeground(self)
    }

    func statusBackgroundColor() -> Color {
        PryTheme.Colors.statusBackground(self)
    }
}

extension Optional where Wrapped == Int {

    func statusTextColor() -> Color {
        self?.statusTextColor() ?? PryTheme.Colors.textSecondary
    }

    func statusBackgroundColor() -> Color {
        self?.statusBackgroundColor() ?? PryTheme.Colors.surface
    }
}
