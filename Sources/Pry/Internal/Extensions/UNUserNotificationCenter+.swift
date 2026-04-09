import UserNotifications

extension UNUserNotificationCenter {

    /// Returns the current notification authorization status without ever
    /// letting the non-`Sendable` ``UNNotificationSettings`` value cross an
    /// actor boundary.
    ///
    /// Swift 6 strict concurrency (as shipped with Xcode 16.x / Swift 6.1)
    /// rejects calls to ``notificationSettings()`` from any actor-isolated
    /// context because the returned `UNNotificationSettings` is not marked
    /// `Sendable`. This helper is `nonisolated`, so the non-sendable value
    /// is consumed within the same nonisolated execution context and only a
    /// `Sendable` `UNAuthorizationStatus` is returned.
    nonisolated func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }
}
