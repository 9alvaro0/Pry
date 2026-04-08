#if DEBUG
import Foundation

extension InspectorStore {

    /// Store with realistic mixed data across all tabs.
    static var preview: InspectorStore {
        let store = InspectorStore()

        // Network: variety of methods, statuses, and states
        store.addNetworkEntry(.mockSuccess)
        store.addNetworkEntry(.mockError)
        store.addNetworkEntry(.mockServerError)
        store.addNetworkEntry(.mockNotification)
        store.addNetworkEntry(.mockNoAuth)
        store.addNetworkEntry(.mockPending)
        store.addNetworkEntry(.mockDelete)
        store.addNetworkEntry(.mockPatch)
        store.addNetworkEntry(.mockFormPost)

        // Console: one of each type
        store.addLogEntry(.mockInfo)
        store.addLogEntry(.mockSuccess)
        store.addLogEntry(.mockWarning)
        store.addLogEntry(.mockError)
        store.addLogEntry(.mockDebug)
        store.addLogEntry(.mockNetwork)

        // Deeplinks
        store.addDeeplinkEntry(.mockCustomScheme)
        store.addDeeplinkEntry(.mockUniversalLink)
        store.addDeeplinkEntry(.mockWidgetLink)

        return store
    }

    /// Store with only network entries.
    static var networkOnly: InspectorStore {
        let store = InspectorStore()
        store.addNetworkEntry(.mockSuccess)
        store.addNetworkEntry(.mockError)
        store.addNetworkEntry(.mockServerError)
        store.addNetworkEntry(.mockPending)
        store.addNetworkEntry(.mockPatch)
        store.addNetworkEntry(.mockFormPost)
        return store
    }

    /// Store with only console logs.
    static var consoleOnly: InspectorStore {
        let store = InspectorStore()
        store.addLogEntry(.mockInfo)
        store.addLogEntry(.mockSuccess)
        store.addLogEntry(.mockWarning)
        store.addLogEntry(.mockError)
        store.addLogEntry(.mockDebug)
        store.addLogEntry(.mockNetwork)
        return store
    }

    /// Store with only deeplinks.
    static var deeplinksOnly: InspectorStore {
        let store = InspectorStore()
        store.addDeeplinkEntry(.mockCustomScheme)
        store.addDeeplinkEntry(.mockUniversalLink)
        store.addDeeplinkEntry(.mockWidgetLink)
        return store
    }
}
#endif
