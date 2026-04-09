import Foundation

/// Extension surface used by `PryPro` to plug Pro-only behavior into the
/// Free SDK without introducing reverse dependencies.
///
/// `Pry` (the Free SDK) declares each hook with a sensible no-op default.
/// `PryPro` installs real implementations during its initialization.
///
/// This API is `@_spi(PryPro)` so it never appears in autocomplete for Free
/// users; only the PryPro module can access it.
@_spi(PryPro)
public enum PryHooks {

    // MARK: - Binary Body Decoder

    /// Optional decoder used by the network logger when a captured request or
    /// response body is not valid UTF-8 text and not a recognized image format.
    ///
    /// `PryPro` installs `ProtobufDecoder.decodeRaw` here so binary protobuf
    /// payloads are rendered as a structured field listing instead of being
    /// shown as `[Binary data: N bytes]`.
    public static var binaryBodyDecoder: (@Sendable (Data) -> String?)? {
        get { storage.lock.withLock { storage.binaryBodyDecoder } }
        set { storage.lock.withLock { storage.binaryBodyDecoder = newValue } }
    }

    // MARK: - Internal Storage

    private static let storage = Storage()

    private final class Storage: @unchecked Sendable {
        let lock = NSLock()
        var binaryBodyDecoder: (@Sendable (Data) -> String?)?
    }
}
