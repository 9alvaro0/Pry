import SwiftUI

private struct PryProStoreKey: EnvironmentKey {
    static let defaultValue: PryProStore? = nil
}

extension EnvironmentValues {

    /// The `PryProStore` injected by the `.pryPro(store:)` modifier.
    ///
    /// Views inside the PryPro UI read Pro state from here, while Free state
    /// (network entries, console logs, etc.) is still reached via
    /// `\.pryStore` on the wrapped ``PryStore``.
    public var pryProStore: PryProStore? {
        get { self[PryProStoreKey.self] }
        set { self[PryProStoreKey.self] = newValue }
    }
}
