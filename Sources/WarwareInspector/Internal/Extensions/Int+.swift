import Foundation
import SwiftUI

extension Int {

    func formatBytes() -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(self))
    }

    func statusTextColor() -> Color {
        InspectorTheme.Colors.statusForeground(self)
    }

    func statusBackgroundColor() -> Color {
        InspectorTheme.Colors.statusBackground(self)
    }
}

extension Optional where Wrapped == Int {

    func statusTextColor() -> Color {
        self?.statusTextColor() ?? InspectorTheme.Colors.textSecondary
    }

    func statusBackgroundColor() -> Color {
        self?.statusBackgroundColor() ?? InspectorTheme.Colors.surface
    }
}
