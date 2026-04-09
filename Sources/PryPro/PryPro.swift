import Foundation
@_exported import Pry
@_spi(PryPro) import Pry

/// PryPro extends Pry with the paid feature set: breakpoints, mocks,
/// replay, request diff, advanced session export, network throttle,
/// protobuf decoding and performance metrics.
///
/// Importing `PryPro` re-exports `Pry`, so consumers only need a single
/// import to get the full inspector:
///
/// ```swift
/// import PryPro
///
/// @main
/// struct MyApp: App {
///     @State private var store = PryStore()
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .pryPro(store: store)
///         }
///     }
/// }
/// ```
///
/// Free users keep using `import Pry` and `.pry(store:)` and never
/// see references to Pro features in their UI.
public enum PryPro {
    /// SDK version of the PryPro module. Bumped together with Pry.
    public static let version = "0.1.0"

    /// Installs all PryPro extension hooks into the Free Pry module.
    ///
    /// Called automatically the first time `.pryPro(store:)` is applied,
    /// but you can also call it manually if you need PryPro behavior
    /// before any view is presented.
    public static func install() {
        installHooksIfNeeded()
    }

    nonisolated(unsafe) private static var hooksInstalled = false
    private static let installLock = NSLock()

    static func installHooksIfNeeded() {
        installLock.withLock {
            guard !hooksInstalled else { return }
            hooksInstalled = true

            // Binary body decoder: render raw protobuf payloads.
            PryHooks.binaryBodyDecoder = { data in
                ProtobufDecoder.decodeRaw(data)
            }
        }
    }
}
