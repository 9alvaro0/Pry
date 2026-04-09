import Foundation
import UserNotifications
import ObjectiveC

/// Swizzles UNUserNotificationCenter delegate methods to automatically
/// capture all push notifications without developer intervention.
final class PushNotificationInterceptor: NSObject, @unchecked Sendable {

    nonisolated(unsafe) static var store: PryStore?

    nonisolated(unsafe) private static var isInstalled = false

    /// Installs the swizzle and ensures a delegate is always set so that
    /// foreground notifications are displayed.
    static func install() {
        guard !isInstalled else { return }
        isInstalled = true

        let center = UNUserNotificationCenter.current()
        let existingDelegate = center.delegate

        // Swizzle setDelegate: so future delegates set by the host app get wrapped
        swizzleDelegateSetup()

        // Set our delegate (wrapping any existing one)
        // This goes through the swizzled setter, which wraps in NotificationDelegateProxy
        if let existingDelegate {
            center.delegate = existingDelegate  // re-set to trigger wrapping
        } else {
            center.delegate = FallbackNotificationDelegate.shared
        }
    }

    // MARK: - Swizzle

    /// Swizzles `setDelegate:` on UNUserNotificationCenter so we can wrap
    /// any delegate the app sets, intercepting notifications transparently.
    private static func swizzleDelegateSetup() {
        let originalSelector = #selector(setter: UNUserNotificationCenter.delegate)
        let swizzledSelector = #selector(UNUserNotificationCenter.pry_setDelegate(_:))

        guard let originalMethod = class_getInstanceMethod(UNUserNotificationCenter.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UNUserNotificationCenter.self, swizzledSelector)
        else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
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
    @objc func pry_setDelegate(_ delegate: UNUserNotificationCenterDelegate?) {
        let proxy: UNUserNotificationCenterDelegate?
        if let delegate {
            // Avoid double-wrapping
            if delegate is NotificationDelegateProxy {
                proxy = delegate
            } else {
                proxy = NotificationDelegateProxy(original: delegate)
                // Keep a strong ref to the proxy (delegate is weak in UNUserNotificationCenter)
                objc_setAssociatedObject(self, &NotificationDelegateProxy.proxyKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        } else {
            proxy = nil
            objc_setAssociatedObject(self, &NotificationDelegateProxy.proxyKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        // After swizzle, calling pry_setDelegate runs the ORIGINAL implementation
        self.pry_setDelegate(proxy)
    }
}

// MARK: - Delegate Proxy

/// Wraps the app's real UNUserNotificationCenterDelegate, forwarding all calls
/// while also capturing notifications for the inspector.
final class NotificationDelegateProxy: NSObject, UNUserNotificationCenterDelegate {

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

// MARK: - Fallback Delegate

/// Minimal delegate that displays notifications in foreground.
/// Used when the host app has no delegate of its own.
final class FallbackNotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    nonisolated(unsafe) static let shared = FallbackNotificationDelegate()

    private override init() { super.init() }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
