import SwiftUI

extension EnvironmentValues {
    /// The inspector store available throughout the SwiftUI view hierarchy.
    ///
    /// ```swift
    /// @Environment(\.inspectorStore) var inspector
    /// inspector.log("Hello", type: .info)
    /// ```
    @Entry public var inspectorStore: InspectorStore = InspectorStore()
}
