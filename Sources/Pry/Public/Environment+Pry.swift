import SwiftUI

extension EnvironmentValues {
    /// The inspector store available throughout the SwiftUI view hierarchy.
    ///
    /// ```swift
    /// @Environment(\.pryStore) var inspector
    /// inspector.log("Hello", type: .info)
    /// ```
    @Entry public var pryStore: PryStore = PryStore()

    /// When true, the inspector is displaying an imported session in read-only mode.
    @Entry @_spi(PryPro) public var pryReadOnly: Bool = false

    /// Accent color override injected by PryPro to replace the default accent.
    @Entry @_spi(PryPro) public var pryAccentOverride: Color? = nil

    /// FAB background color override injected by PryPro.
    @Entry @_spi(PryPro) public var pryFabColorOverride: Color? = nil

    /// FAB foreground color override injected by PryPro.
    @Entry @_spi(PryPro) public var pryFabForegroundOverride: Color? = nil
}
