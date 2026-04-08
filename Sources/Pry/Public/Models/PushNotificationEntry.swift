import Foundation

/// Represents a push notification received by the app.
public struct PushNotificationEntry: Identifiable, Codable, Sendable {
    /// Unique identifier for this entry.
    public var id = UUID()
    /// When the notification was received.
    public let timestamp: Date
    /// The notification title.
    public let title: String?
    /// The notification body text.
    public let body: String?
    /// The notification subtitle.
    public let subtitle: String?
    /// The badge count, if specified.
    public let badge: Int?
    /// The sound name, if specified.
    public let sound: String?
    /// The notification category identifier for actionable notifications.
    public let categoryIdentifier: String?
    /// The thread identifier used for notification grouping.
    public let threadIdentifier: String?
    /// Flattened key-value pairs from the APNs userInfo dictionary.
    public let userInfo: [String: String]
    /// The raw APNs payload as pretty-printed JSON.
    public let rawPayload: String?

    /// The title to display, falling back to "No Title" when nil.
    public var displayTitle: String {
        title ?? "No Title"
    }

    /// The body text to display, falling back to subtitle or "No content".
    public var displayBody: String {
        body ?? subtitle ?? "No content"
    }
}
