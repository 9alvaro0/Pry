import Foundation

/// Observable store that holds all captured inspector entries.
///
/// Create one instance and pass it to `.inspector(store:)`.
/// Access from child views via the environment:
///
/// ```swift
/// @Environment(\.inspectorStore) var inspector
/// inspector.log("Something happened", type: .info)
/// ```
@Observable public final class InspectorStore: @unchecked Sendable {

    // MARK: - State

    public private(set) var networkEntries: [NetworkEntry] = []
    public private(set) var logEntries: [LogEntry] = []
    public private(set) var deeplinkEntries: [DeeplinkEntry] = []

    // MARK: - Configuration

    private let maxNetworkEntries: Int
    private let maxLogEntries: Int
    private let maxDeeplinkEntries: Int

    // MARK: - Init

    public init(
        maxNetworkEntries: Int = 200,
        maxLogEntries: Int = 500,
        maxDeeplinkEntries: Int = 100
    ) {
        self.maxNetworkEntries = maxNetworkEntries
        self.maxLogEntries = maxLogEntries
        self.maxDeeplinkEntries = maxDeeplinkEntries
    }

    // MARK: - Network (internal - fed by NetworkLogger)

    func addNetworkEntry(_ entry: NetworkEntry) {
        networkEntries.insert(entry, at: 0)
        if networkEntries.count > maxNetworkEntries {
            networkEntries.removeLast(networkEntries.count - maxNetworkEntries)
        }
    }

    /// Updates an existing entry (by ID) with response data, or adds it if not found.
    func updateOrAddNetworkEntry(_ entry: NetworkEntry) {
        if let index = networkEntries.firstIndex(where: { $0.id == entry.id }) {
            networkEntries[index] = entry
        } else {
            addNetworkEntry(entry)
        }
    }

    // MARK: - Console Logging

    /// Logs a message to the inspector console and Xcode output.
    ///
    /// ```swift
    /// @Environment(\.inspectorStore) var inspector
    /// inspector.log("User logged in", type: .success)
    /// ```
    public func log(
        _ message: String,
        type: LogType = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        print(message)

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

    // MARK: - Clear

    public func clearNetwork() { networkEntries.removeAll() }
    public func clearLogs() { logEntries.removeAll() }
    public func clearDeeplinks() { deeplinkEntries.removeAll() }

    public func clearAll() {
        networkEntries.removeAll()
        logEntries.removeAll()
        deeplinkEntries.removeAll()
    }
}
