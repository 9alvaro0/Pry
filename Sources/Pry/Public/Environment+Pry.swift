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

    /// Gold glow color injected by PryPro for premium visual touches
    /// (borders, shadows, highlights). When nil, no glow effects are applied.
    @Entry @_spi(PryPro) public var pryProGlow: Color? = nil
}
