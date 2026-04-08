import Foundation

/// Represents a console log entry captured by the inspector.
public struct LogEntry: Identifiable, Codable, Sendable {
    public var id = UUID()
    public let timestamp: Date
    public let type: LogType
    public let message: String
    public let file: String?
    public let function: String?
    public let line: Int?
    public let additionalInfo: [String: String]?

    public var location: String? {
        guard let file else { return nil }
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        return line.map { "\(fileName):\($0)" } ?? fileName
    }
}
