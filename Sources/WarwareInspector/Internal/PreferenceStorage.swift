import Foundation

/// Persists inspector preferences to UserDefaults with a namespaced prefix.
enum PreferenceStorage {
    private static let prefix = "warware_inspector_"
    private static let defaults = UserDefaults.standard

    // MARK: - Keys

    enum Key: String {
        case showErrorBadge
        case printToConsole
        case fabOnLeft
        case fabDraggable
        case fabDragOffsetX
        case fabDragOffsetY
        case triggerOverride
        case networkThrottle
        case blacklistedHosts
    }

    // MARK: - Read

    static func bool(for key: Key, default defaultValue: Bool) -> Bool {
        let fullKey = prefix + key.rawValue
        guard defaults.object(forKey: fullKey) != nil else { return defaultValue }
        return defaults.bool(forKey: fullKey)
    }

    static func string(for key: Key) -> String? {
        defaults.string(forKey: prefix + key.rawValue)
    }

    static func integer(for key: Key) -> Int? {
        let fullKey = prefix + key.rawValue
        guard defaults.object(forKey: fullKey) != nil else { return nil }
        return defaults.integer(forKey: fullKey)
    }

    static func double(for key: Key) -> Double {
        defaults.double(forKey: prefix + key.rawValue)
    }

    static func stringSet(for key: Key) -> Set<String> {
        guard let array = defaults.stringArray(forKey: prefix + key.rawValue) else { return [] }
        return Set(array)
    }

    // MARK: - Write

    static func set(_ value: Bool, for key: Key) {
        defaults.set(value, forKey: prefix + key.rawValue)
    }

    static func set(_ value: String?, for key: Key) {
        defaults.set(value, forKey: prefix + key.rawValue)
    }

    static func set(_ value: Int, for key: Key) {
        defaults.set(value, forKey: prefix + key.rawValue)
    }

    static func set(_ value: Double, for key: Key) {
        defaults.set(value, forKey: prefix + key.rawValue)
    }

    static func set(_ value: Set<String>, for key: Key) {
        defaults.set(Array(value), forKey: prefix + key.rawValue)
    }
}
