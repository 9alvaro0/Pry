import Foundation
import SwiftUI

@_spi(PryPro) public extension Int {

    @_spi(PryPro) public func formatBytes() -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(self))
    }

    @_spi(PryPro) public func statusTextColor() -> Color {
        PryTheme.Colors.statusForeground(self)
    }

    @_spi(PryPro) public func statusBackgroundColor() -> Color {
        PryTheme.Colors.statusBackground(self)
    }
}

@_spi(PryPro) public extension Optional where Wrapped == Int {

    @_spi(PryPro) public func statusTextColor() -> Color {
        self?.statusTextColor() ?? PryTheme.Colors.textSecondary
    }

    @_spi(PryPro) public func statusBackgroundColor() -> Color {
        self?.statusBackgroundColor() ?? PryTheme.Colors.surface
    }
}
