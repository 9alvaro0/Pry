import Foundation

/// Represents a push notification received by the app.
public struct PushNotificationEntry: Identifiable, Codable, Sendable {
    public var id = UUID()
    public let timestamp: Date
    public let title: String?
    public let body: String?
    public let subtitle: String?
    public let badge: Int?
    public let sound: String?
    public let categoryIdentifier: String?
    public let threadIdentifier: String?
    public let userInfo: [String: String]
    /// The raw APNs payload as pretty-printed JSON.
    public let rawPayload: String?

    public var displayTitle: String {
        title ?? "No Title"
    }

    public var displayBody: String {
        body ?? subtitle ?? "No content"
    }
}
