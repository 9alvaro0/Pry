import Foundation

/// Controls how the inspector UI is triggered.
///
/// ```swift
/// .inspector(store: store, trigger: .floatingButton)
/// .inspector(store: store, trigger: .shake)
/// .inspector(store: store, trigger: [.floatingButton, .shake])
/// ```
public struct InspectorTrigger: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Shows a floating ladybug button in the bottom-right corner.
    public static let floatingButton = InspectorTrigger(rawValue: 1 << 0)

    /// Opens the inspector when the device is shaken.
    public static let shake = InspectorTrigger(rawValue: 1 << 1)

    /// Default trigger: floating button.
    public static let `default`: InspectorTrigger = .floatingButton
}
