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

    public private(set) var networkEntries: [NetworkEntry] = []
    public private(set) var logEntries: [LogEntry] = []
    public private(set) var deeplinkEntries: [DeeplinkEntry] = []
    public private(set) var pushNotificationEntries: [PushNotificationEntry] = []

    // MARK: - Pins

    public var pinnedRequestIDs: Set<UUID> = []

    public func togglePin(_ id: UUID) {
        if pinnedRequestIDs.contains(id) {
            pinnedRequestIDs.remove(id)
        } else {
            pinnedRequestIDs.insert(id)
        }
    }

    public func isPinned(_ id: UUID) -> Bool {
        pinnedRequestIDs.contains(id)
    }

    // MARK: - Blacklist

    public var blacklistedHosts: Set<String> = [] {
        didSet { guard !isLoadingPreferences else { return }; PreferenceStorage.set(blacklistedHosts, for: .blacklistedHosts) }
    }

    // MARK: - Preferences

    public var showErrorBadge: Bool = true {
        didSet { guard !isLoadingPreferences else { return }; PreferenceStorage.set(showErrorBadge, for: .showErrorBadge) }
    }

    public var printToConsole: Bool = true {
        didSet { guard !isLoadingPreferences else { return }; PreferenceStorage.set(printToConsole, for: .printToConsole) }
    }

    public var fabOnLeft: Bool = false {
        didSet { guard !isLoadingPreferences else { return }; PreferenceStorage.set(fabOnLeft, for: .fabOnLeft) }
    }

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

    // MARK: - Network Throttle

    public var networkThrottle: NetworkThrottle = .none {
        didSet {
            PryConfig.shared.throttle = networkThrottle
            guard !isLoadingPreferences else { return }
            PreferenceStorage.set(networkThrottle.rawValue, for: .networkThrottle)
        }
    }

    // MARK: - Mock Rules

    public private(set) var mockRules: [MockRule] = []

    public var isMockingEnabled: Bool {
        mockRules.contains(where: \.isEnabled)
    }

    public func addMockRule(_ rule: MockRule) {
        mockRules.append(rule)
        syncMockRules()
    }

    public func removeMockRule(_ id: UUID) {
        mockRules.removeAll { $0.id == id }
        syncMockRules()
    }

    public func toggleMockRule(_ id: UUID) {
        guard let index = mockRules.firstIndex(where: { $0.id == id }) else { return }
        mockRules[index].isEnabled.toggle()
        syncMockRules()
    }

    private func syncMockRules() {
        PryConfig.shared.mockRules = mockRules
        PryConfig.shared.isMockingEnabled = isMockingEnabled
    }

    // MARK: - Breakpoint Rules

    public private(set) var breakpointRules: [BreakpointRule] = []

    public var isBreakpointEnabled: Bool {
        breakpointRules.contains(where: \.isEnabled)
    }

    public func addBreakpointRule(_ rule: BreakpointRule) {
        breakpointRules.append(rule)
        syncBreakpointRules()
    }

    public func removeBreakpointRule(_ id: UUID) {
        breakpointRules.removeAll { $0.id == id }
        syncBreakpointRules()
    }

    public func toggleBreakpointRule(_ id: UUID) {
        guard let index = breakpointRules.firstIndex(where: { $0.id == id }) else { return }
        breakpointRules[index].isEnabled.toggle()
        syncBreakpointRules()
    }

    func syncBreakpointRules() {
        PryConfig.shared.breakpointRules = breakpointRules
        PryConfig.shared.isBreakpointEnabled = isBreakpointEnabled
    }

    // MARK: - Configuration

    private let maxNetworkEntries: Int
    private let maxLogEntries: Int
    private let maxDeeplinkEntries: Int
    private let maxPushEntries: Int

    // MARK: - Init

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

        if let throttleRaw = PreferenceStorage.string(for: .networkThrottle),
           let throttle = NetworkThrottle(rawValue: throttleRaw) {
            networkThrottle = throttle
        }
    }

    // MARK: - Network (internal - fed by NetworkLogger)

    func addNetworkEntry(_ entry: NetworkEntry) {
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

    func addLogEntry(_ entry: LogEntry) {
        logEntries.insert(entry, at: 0)
        if logEntries.count > maxLogEntries {
            logEntries.removeLast(logEntries.count - maxLogEntries)
        }
    }

    // MARK: - Deeplinks

    /// Logs a received deeplink URL.
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

    func addDeeplinkEntry(_ entry: DeeplinkEntry) {
        deeplinkEntries.insert(entry, at: 0)
        if deeplinkEntries.count > maxDeeplinkEntries {
            deeplinkEntries.removeLast(deeplinkEntries.count - maxDeeplinkEntries)
        }
    }

    // MARK: - Push Notifications

    /// Logs a received push notification.
    /// Logs a push notification manually.
    /// Note: push notifications are captured automatically when the inspector is started.
    /// Use this only for manual logging if needed.
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

    func addPushNotification(_ entry: PushNotificationEntry) {
        pushNotificationEntries.insert(entry, at: 0)
        if pushNotificationEntries.count > maxPushEntries {
            pushNotificationEntries.removeLast(pushNotificationEntries.count - maxPushEntries)
        }
    }

    // MARK: - Remove

    public func removeNetworkEntry(_ id: UUID) {
        networkEntries.removeAll { $0.id == id }
        pinnedRequestIDs.remove(id)
    }

    public func removeLogEntry(_ id: UUID) {
        logEntries.removeAll { $0.id == id }
    }

    public func removeDeeplinkEntry(_ id: UUID) {
        deeplinkEntries.removeAll { $0.id == id }
    }

    public func removePushEntry(_ id: UUID) {
        pushNotificationEntries.removeAll { $0.id == id }
    }

    // MARK: - Clear

    public func clearNetwork() { networkEntries.removeAll() }
    public func clearLogs() { logEntries.removeAll() }
    public func clearDeeplinks() { deeplinkEntries.removeAll() }
    public func clearPush() { pushNotificationEntries.removeAll() }

    public func clearAll() {
        networkEntries.removeAll()
        logEntries.removeAll()
        deeplinkEntries.removeAll()
        pushNotificationEntries.removeAll()
    }
}
