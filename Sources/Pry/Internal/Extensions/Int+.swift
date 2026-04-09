import Foundation
import SwiftUI

package extension Int {

    package func formatBytes() -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(self))
    }

    package func statusTextColor() -> Color {
        PryTheme.Colors.statusForeground(self)
    }

    package func statusBackgroundColor() -> Color {
        PryTheme.Colors.statusBackground(self)
    }
}

package extension Optional where Wrapped == Int {

    package func statusTextColor() -> Color {
        self?.statusTextColor() ?? PryTheme.Colors.textSecondary
    }

    package func statusBackgroundColor() -> Color {
        self?.statusBackgroundColor() ?? PryTheme.Colors.surface
    }
}
