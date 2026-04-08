import Foundation

/// Controls how the inspector UI is triggered.
///
/// ```swift
/// .pry(store: store, trigger: .floatingButton)
/// .pry(store: store, trigger: .shake)
/// .pry(store: store, trigger: [.floatingButton, .shake])
/// ```
public struct PryTrigger: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Shows a floating ladybug button in the bottom-right corner.
    public static let floatingButton = PryTrigger(rawValue: 1 << 0)

    /// Opens the inspector when the device is shaken.
    public static let shake = PryTrigger(rawValue: 1 << 1)

    /// Default trigger: floating button.
    public static let `default`: PryTrigger = .floatingButton
}
