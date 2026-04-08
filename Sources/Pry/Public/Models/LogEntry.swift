import Foundation

/// Represents a console log entry captured by the inspector.
public struct LogEntry: Identifiable, Codable, Sendable {
    /// Unique identifier for this entry.
    public var id = UUID()
    /// When the log was recorded.
    public let timestamp: Date
    /// The severity or category of the log.
    public let type: LogType
    /// The log message text.
    public let message: String
    /// The source file that produced this log.
    public let file: String?
    /// The function name that produced this log.
    public let function: String?
    /// The source line number.
    public let line: Int?
    /// Optional key-value pairs with extra context.
    public let additionalInfo: [String: String]?

    /// A formatted "FileName:Line" string for display, if available.
    public var location: String? {
        guard let file else { return nil }
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        return line.map { "\(fileName):\($0)" } ?? fileName
    }
}
