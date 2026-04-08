import Foundation
import UserNotifications
import ObjectiveC

/// Swizzles UNUserNotificationCenter delegate methods to automatically
/// capture all push notifications without developer intervention.
final class PushNotificationInterceptor: NSObject, @unchecked Sendable {

    nonisolated(unsafe) static var store: InspectorStore?

    /// Installs the swizzle. Call once at inspector start.
    static func install() {
        swizzleDelegateSetup()
    }

    // MARK: - Swizzle

    /// Swizzles `setDelegate:` on UNUserNotificationCenter so we can wrap
    /// any delegate the app sets, intercepting notifications transparently.
    private static func swizzleDelegateSetup() {
        let originalSelector = #selector(setter: UNUserNotificationCenter.delegate)
        let swizzledSelector = #selector(UNUserNotificationCenter.inspector_setDelegate(_:))

        guard let originalMethod = class_getInstanceMethod(UNUserNotificationCenter.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UNUserNotificationCenter.self, swizzledSelector)
        else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)

        // If a delegate is already set, wrap it now
        if let existingDelegate = UNUserNotificationCenter.current().delegate {
            UNUserNotificationCenter.current().inspector_setDelegate(existingDelegate)
        }
    }

    // MARK: - Log

    static func logNotification(_ notification: UNNotification) {
        guard let store else { return }

        let content = notification.request.content

        let userInfo = content.userInfo
        let flatUserInfo = userInfo.reduce(into: [String: String]()) { result, pair in
            if let key = pair.key as? String {
                result[key] = String(describing: pair.value)
            }
        }

        // Raw payload as JSON
        let rawPayload: String? = {
            guard let data = try? JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted),
                  let str = String(data: data, encoding: .utf8) else { return nil }
            return str
        }()

        let entry = PushNotificationEntry(
            timestamp: notification.date,
            title: content.title.isEmpty ? nil : content.title,
            body: content.body.isEmpty ? nil : content.body,
            subtitle: content.subtitle.isEmpty ? nil : content.subtitle,
            badge: content.badge?.intValue,
            sound: content.sound != nil ? "enabled" : nil,
            categoryIdentifier: content.categoryIdentifier.isEmpty ? nil : content.categoryIdentifier,
            threadIdentifier: content.threadIdentifier.isEmpty ? nil : content.threadIdentifier,
            userInfo: flatUserInfo,
            rawPayload: rawPayload
        )

        Task { @MainActor in
            store.addPushNotification(entry)
        }
    }
}

// MARK: - UNUserNotificationCenter Swizzle

extension UNUserNotificationCenter {

    /// Swizzled `setDelegate:` — wraps the real delegate in a proxy.
    @objc func inspector_setDelegate(_ delegate: UNUserNotificationCenterDelegate?) {
        let proxy: UNUserNotificationCenterDelegate?
        if let delegate {
            proxy = NotificationDelegateProxy(original: delegate)
            // Keep a strong ref to the proxy
            objc_setAssociatedObject(self, &NotificationDelegateProxy.proxyKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } else {
            proxy = nil
        }
        // Call the original (swizzled) setter with our proxy
        self.inspector_setDelegate(proxy)
    }
}

// MARK: - Delegate Proxy

/// Wraps the app's real UNUserNotificationCenterDelegate, forwarding all calls
/// while also capturing notifications for the inspector.
private class NotificationDelegateProxy: NSObject, UNUserNotificationCenterDelegate {

    nonisolated(unsafe) static var proxyKey = 0

    let original: UNUserNotificationCenterDelegate

    init(original: UNUserNotificationCenterDelegate) {
        self.original = original
        super.init()
    }

    // Foreground notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        PushNotificationInterceptor.logNotification(notification)

        if original.responds(to: #selector(userNotificationCenter(_:willPresent:withCompletionHandler:))) {
            original.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }

    // Tapped notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        PushNotificationInterceptor.logNotification(response.notification)

        if original.responds(to: #selector(userNotificationCenter(_:didReceive:withCompletionHandler:))) {
            original.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
        } else {
            completionHandler()
        }
    }

    // Forward any other selector calls to the original
    override func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector) || original.responds(to: aSelector)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if original.responds(to: aSelector) { return original }
        return super.forwardingTarget(for: aSelector)
    }
}
