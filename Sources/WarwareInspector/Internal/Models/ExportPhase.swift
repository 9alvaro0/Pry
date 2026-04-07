import Foundation

enum ExportPhase: Sendable {
    case deviceInfo
    case networkLogs
    case consoleLogs
    case deeplinkLogs
    case writingFile

    var message: String {
        switch self {
        case .deviceInfo: "Gathering device info..."
        case .networkLogs: "Exporting Network logs..."
        case .consoleLogs: "Exporting Console logs..."
        case .deeplinkLogs: "Exporting Deeplink logs..."
        case .writingFile: "Writing file..."
        }
    }
}
