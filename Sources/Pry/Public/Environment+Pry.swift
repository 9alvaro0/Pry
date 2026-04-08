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
    @Entry var pryReadOnly: Bool = false
}
