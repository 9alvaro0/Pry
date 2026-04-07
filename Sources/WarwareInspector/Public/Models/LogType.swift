import SwiftUI

/// Defines the different log types available in the Inspector.
///
/// Each type has an associated color and icon for visual categorization.
public enum LogType: String, CaseIterable, Codable, Sendable {

    case network = "Network"
    case error = "Error"
    case warning = "Warning"
    case info = "Info"
    case success = "Success"
    case debug = "Debug"

    var systemImage: String {
        switch self {
        case .network: "network"
        case .error: "exclamationmark.triangle.fill"
        case .warning: "exclamationmark.triangle"
        case .info: "info.circle"
        case .success: "checkmark.circle.fill"
        case .debug: "ladybug.fill"
        }
    }

    var color: Color {
        switch self {
        case .network: InspectorTheme.Colors.network
        case .error: InspectorTheme.Colors.error
        case .warning: InspectorTheme.Colors.warning
        case .info: InspectorTheme.Colors.textSecondary
        case .success: InspectorTheme.Colors.success
        case .debug: InspectorTheme.Colors.syntaxBool
        }
    }
}
