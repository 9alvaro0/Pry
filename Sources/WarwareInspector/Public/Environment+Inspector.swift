import SwiftUI

extension EnvironmentValues {
    /// The inspector store available throughout the SwiftUI view hierarchy.
    ///
    /// ```swift
    /// @Environment(\.inspectorStore) var inspector
    /// inspector.log("Hello", type: .info)
    /// ```
    @Entry public var inspectorStore: InspectorStore = InspectorStore()

    /// When true, the inspector is displaying an imported session in read-only mode.
    @Entry var inspectorReadOnly: Bool = false
}
