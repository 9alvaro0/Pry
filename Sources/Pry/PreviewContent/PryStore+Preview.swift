#if DEBUG
import Foundation

extension PryStore {

    /// Store with realistic mixed data across all tabs.
    @_spi(PryPro) public static var preview: PryStore {
        let store = PryStore()

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
        store.addNetworkEntry(.mockRedirect)
        store.addNetworkEntry(.mockMocked)
        store.addNetworkEntry(.mockGraphQLQuery)
        store.addNetworkEntry(.mockGraphQLMutation)
        store.addNetworkEntry(.mockGraphQLError)

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

        // Push Notifications
        store.addPushNotification(.mockPromo)
        store.addPushNotification(.mockChat)
        store.addPushNotification(.mockSilent)

        return store
    }

    /// Store with only network entries.
    static var networkOnly: PryStore {
        let store = PryStore()
        store.addNetworkEntry(.mockSuccess)
        store.addNetworkEntry(.mockError)
        store.addNetworkEntry(.mockServerError)
        store.addNetworkEntry(.mockPending)
        store.addNetworkEntry(.mockPatch)
        store.addNetworkEntry(.mockFormPost)
        store.addNetworkEntry(.mockMocked)
        store.addNetworkEntry(.mockGraphQLQuery)
        store.addNetworkEntry(.mockGraphQLMutation)
        return store
    }

    /// Store with only console logs.
    static var consoleOnly: PryStore {
        let store = PryStore()
        store.addLogEntry(.mockInfo)
        store.addLogEntry(.mockSuccess)
        store.addLogEntry(.mockWarning)
        store.addLogEntry(.mockError)
        store.addLogEntry(.mockDebug)
        store.addLogEntry(.mockNetwork)
        return store
    }

    /// Store with only deeplinks.
    static var deeplinksOnly: PryStore {
        let store = PryStore()
        store.addDeeplinkEntry(.mockCustomScheme)
        store.addDeeplinkEntry(.mockUniversalLink)
        store.addDeeplinkEntry(.mockWidgetLink)
        return store
    }

    /// Store with only push notifications.
    static var pushOnly: PryStore {
        let store = PryStore()
        store.addPushNotification(.mockPromo)
        store.addPushNotification(.mockChat)
        store.addPushNotification(.mockSilent)
        return store
    }
}
#endif
