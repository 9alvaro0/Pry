import Foundation

/// Observable store that holds all captured inspector entries.
///
/// Create one instance and pass it to `.pry(store:)`.
/// Access from child views via the environment:
///
/// ```swift
/// @Environment(\.pryStore) var inspector
/// inspector.log("Something happened", type: .info)
/// ```
@Observable public final class PryStore: @unchecked Sendable {

    /// Suppresses didSet persistence during initial load.
    private var isLoadingPreferences = false

    // MARK: - State

    /// All captured network request/response entries, newest first.
    public private(set) var networkEntries: [NetworkEntry] = []
    /// All captured console log entries, newest first.
    public private(set) var logEntries: [LogEntry] = []
    /// All captured deeplink entries, newest first.
    public private(set) var deeplinkEntries: [DeeplinkEntry] = []
    /// All captured push notification entries, newest first.
    public private(set) var pushNotificationEntries: [PushNotificationEntry] = []

    // MARK: - Pins

    /// The set of network entry IDs that the user has pinned.
    public var pinnedRequestIDs: Set<UUID> = []

    /// Toggles the pinned state of a network entry.
    /// - Parameter id: The identifier of the network entry to pin or unpin.
    public func togglePin(_ id: UUID) {
        if pinnedRequestIDs.contains(id) {
            pinnedRequestIDs.remove(id)
        } else {
            pinnedRequestIDs.insert(id)
        }
    }

    /// Returns whether a network entry is currently pinned.
    /// - Parameter id: The identifier of the network entry.
    /// - Returns: `true` if the entry is pinned.
    public func isPinned(_ id: UUID) -> Bool {
        pinnedRequestIDs.contains(id)
    }

    // MARK: - Blacklist

    /// Hosts excluded from network capture. Persisted across sessions.
    public var blacklistedHosts: Set<String> = [] {
        didSet { guard !isLoadingPreferences else { return }; PreferenceStorage.set(blacklistedHosts, for: .blacklistedHosts) }
    }

    // MARK: - Preferences

    /// Whether to show the error count badge on the floating action button. Persisted.
    public var showErrorBadge: Bool = true {
        didSet { guard !isLoadingPreferences else { return }; PreferenceStorage.set(showErrorBadge, for: .showErrorBadge) }
    }

    /// Whether logged messages are also printed to the Xcode console. Persisted.
    public var printToConsole: Bool = true {
        didSet { guard !isLoadingPreferences else { return }; PreferenceStorage.set(printToConsole, for: .printToConsole) }
    }

    /// Places the floating action button on the left side of the screen. Persisted.
    public var fabOnLeft: Bool = false {
        didSet { guard !isLoadingPreferences else { return }; PreferenceStorage.set(fabOnLeft, for: .fabOnLeft) }
    }

    /// Allows the floating action button to be repositioned by dragging. Persisted.
    public var fabDraggable: Bool = false {
        didSet {
            guard !isLoadingPreferences else { return }
            PreferenceStorage.set(fabDraggable, for: .fabDraggable)
            if !fabDraggable { fabDragOffset = .zero }
        }
    }

    var fabDragOffset: CGSize = .zero {
        didSet {
            guard !isLoadingPreferences else { return }
            PreferenceStorage.set(fabDragOffset.width, for: .fabDragOffsetX)
            PreferenceStorage.set(fabDragOffset.height, for: .fabDragOffsetY)
        }
    }

    var triggerOverride: PryTrigger? {
        didSet {
            guard !isLoadingPreferences else { return }
            PreferenceStorage.set(triggerOverride?.rawValue ?? -1, for: .triggerOverride)
        }
    }

    // MARK: - UI State (persists across sheet open/close)

    var networkSortOrder: Int = 0
    var networkSelectedHost: String?
    var networkShowStats: Bool = false
    var networkSelectedFilter: String?

    // MARK: - Configuration

    private let maxNetworkEntries: Int
    private let maxLogEntries: Int
    private let maxDeeplinkEntries: Int
    private let maxPushEntries: Int

    // MARK: - Init

    /// Creates a new inspector store with configurable entry limits.
    /// - Parameters:
    ///   - maxNetworkEntries: Maximum number of network entries to retain. Defaults to 200.
    ///   - maxLogEntries: Maximum number of log entries to retain. Defaults to 500.
    ///   - maxDeeplinkEntries: Maximum number of deeplink entries to retain. Defaults to 100.
    ///   - maxPushEntries: Maximum number of push notification entries to retain. Defaults to 100.
    public init(
        maxNetworkEntries: Int = 200,
        maxLogEntries: Int = 500,
        maxDeeplinkEntries: Int = 100,
        maxPushEntries: Int = 100
    ) {
        self.maxNetworkEntries = maxNetworkEntries
        self.maxLogEntries = maxLogEntries
        self.maxDeeplinkEntries = maxDeeplinkEntries
        self.maxPushEntries = maxPushEntries

        // Load persisted preferences
        loadPreferences()
    }

    private func loadPreferences() {
        isLoadingPreferences = true
        defer { isLoadingPreferences = false }

        showErrorBadge = PreferenceStorage.bool(for: .showErrorBadge, default: true)
        printToConsole = PreferenceStorage.bool(for: .printToConsole, default: true)
        fabOnLeft = PreferenceStorage.bool(for: .fabOnLeft, default: false)
        fabDraggable = PreferenceStorage.bool(for: .fabDraggable, default: false)
        blacklistedHosts = PreferenceStorage.stringSet(for: .blacklistedHosts)

        let offsetX = PreferenceStorage.double(for: .fabDragOffsetX)
        let offsetY = PreferenceStorage.double(for: .fabDragOffsetY)
        fabDragOffset = CGSize(width: offsetX, height: offsetY)

        if let triggerRaw = PreferenceStorage.integer(for: .triggerOverride), triggerRaw >= 0 {
            triggerOverride = PryTrigger(rawValue: triggerRaw)
        }
    }

    // MARK: - Network (internal - fed by NetworkLogger)

    @_spi(PryPro) public func addNetworkEntry(_ entry: NetworkEntry) {
        networkEntries.insert(entry, at: 0)
        if networkEntries.count > maxNetworkEntries {
            networkEntries.removeLast(networkEntries.count - maxNetworkEntries)
        }
    }

    // MARK: - Console Logging

    /// Logs a message to the inspector console and Xcode output.
    ///
    /// ```swift
    /// @Environment(\.pryStore) var inspector
    /// inspector.log("User logged in", type: .success)
    /// ```
    public func log(
        _ message: String,
        type: LogType = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if printToConsole {
            print(message)
        }

        let entry = LogEntry(
            timestamp: Date(),
            type: type,
            message: message,
            file: (file as NSString).lastPathComponent,
            function: function,
            line: line,
            additionalInfo: nil
        )

        Task { @MainActor in
            self.addLogEntry(entry)
        }
    }

    @_spi(PryPro) public func addLogEntry(_ entry: LogEntry) {
        logEntries.insert(entry, at: 0)
        if logEntries.count > maxLogEntries {
            logEntries.removeLast(logEntries.count - maxLogEntries)
        }
    }

    // MARK: - Deeplinks

    /// Logs a received deeplink URL.
    /// - Parameter url: The deeplink or universal link URL to record.
    public func logDeeplink(url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        let queryParams = (components?.queryItems ?? []).map {
            DeeplinkEntry.QueryParameter(name: $0.name, value: $0.value)
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        let entry = DeeplinkEntry(
            timestamp: Date(),
            url: url.absoluteString,
            scheme: url.scheme,
            host: url.host,
            path: url.path.isEmpty ? "/" : url.path,
            pathComponents: pathComponents,
            queryParameters: queryParams,
            fragment: url.fragment
        )

        Task { @MainActor in
            self.addDeeplinkEntry(entry)
        }
    }

    @_spi(PryPro) public func addDeeplinkEntry(_ entry: DeeplinkEntry) {
        deeplinkEntries.insert(entry, at: 0)
        if deeplinkEntries.count > maxDeeplinkEntries {
            deeplinkEntries.removeLast(deeplinkEntries.count - maxDeeplinkEntries)
        }
    }

    // MARK: - Push Notifications

    /// Logs a push notification manually.
    ///
    /// Push notifications are captured automatically when the inspector is started.
    /// Use this only for manual logging if needed.
    /// - Parameters:
    ///   - title: The notification title.
    ///   - body: The notification body text.
    ///   - subtitle: The notification subtitle.
    ///   - badge: The badge count, if any.
    ///   - sound: The sound name, if any.
    ///   - categoryIdentifier: The notification category identifier.
    ///   - threadIdentifier: The thread identifier for grouping.
    ///   - userInfo: The raw APNs payload dictionary.
    public func logPushNotification(
        title: String?,
        body: String?,
        subtitle: String?,
        badge: Int?,
        sound: String?,
        categoryIdentifier: String?,
        threadIdentifier: String?,
        userInfo: [String: Any] = [:]
    ) {
        let flatUserInfo = userInfo.reduce(into: [String: String]()) { result, pair in
            if let key = pair.key as? String {
                result[key] = String(describing: pair.value)
            }
        }

        let rawPayload: String? = {
            guard !userInfo.isEmpty,
                  let data = try? JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted),
                  let str = String(data: data, encoding: .utf8) else { return nil }
            return str
        }()

        let entry = PushNotificationEntry(
            timestamp: Date(),
            title: title,
            body: body,
            subtitle: subtitle,
            badge: badge,
            sound: sound,
            categoryIdentifier: categoryIdentifier,
            threadIdentifier: threadIdentifier,
            userInfo: flatUserInfo,
            rawPayload: rawPayload
        )

        Task { @MainActor in
            self.addPushNotification(entry)
        }
    }

    @_spi(PryPro) public func addPushNotification(_ entry: PushNotificationEntry) {
        pushNotificationEntries.insert(entry, at: 0)
        if pushNotificationEntries.count > maxPushEntries {
            pushNotificationEntries.removeLast(pushNotificationEntries.count - maxPushEntries)
        }
    }

    // MARK: - Remove

    /// Removes a single network entry and unpins it if pinned.
    /// - Parameter id: The identifier of the entry to remove.
    public func removeNetworkEntry(_ id: UUID) {
        networkEntries.removeAll { $0.id == id }
        pinnedRequestIDs.remove(id)
    }

    /// Removes a single log entry.
    /// - Parameter id: The identifier of the entry to remove.
    public func removeLogEntry(_ id: UUID) {
        logEntries.removeAll { $0.id == id }
    }

    /// Removes a single deeplink entry.
    /// - Parameter id: The identifier of the entry to remove.
    public func removeDeeplinkEntry(_ id: UUID) {
        deeplinkEntries.removeAll { $0.id == id }
    }

    /// Removes a single push notification entry.
    /// - Parameter id: The identifier of the entry to remove.
    public func removePushEntry(_ id: UUID) {
        pushNotificationEntries.removeAll { $0.id == id }
    }

    // MARK: - Clear

    /// Removes all captured network entries.
    public func clearNetwork() { networkEntries.removeAll() }
    /// Removes all captured log entries.
    public func clearLogs() { logEntries.removeAll() }
    /// Removes all captured deeplink entries.
    public func clearDeeplinks() { deeplinkEntries.removeAll() }
    /// Removes all captured push notification entries.
    public func clearPush() { pushNotificationEntries.removeAll() }

    /// Removes all captured entries across every category.
    public func clearAll() {
        networkEntries.removeAll()
        logEntries.removeAll()
        deeplinkEntries.removeAll()
        pushNotificationEntries.removeAll()
    }
}
