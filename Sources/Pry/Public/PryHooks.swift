import Foundation
import SwiftUI

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

    // MARK: - Pro Detail Toolbar

    /// Returns the extra toolbar actions that PryPro adds to the request
    /// detail ``Menu``. The Free view renders them as a separate section
    /// inside the existing ellipsis menu.
    ///
    /// Each ``ProToolbarAction`` carries an `id` that the Free view passes
    /// back through ``proDetailActionHandler`` when the user taps it.
    public static var proDetailActions: (@MainActor @Sendable (NetworkEntry) -> [ProToolbarAction])? {
        get { storage.lock.withLock { storage.proDetailActions } }
        set { storage.lock.withLock { storage.proDetailActions = newValue } }
    }

    /// Called by the Free detail view when the user taps a Pro toolbar action.
    /// PryPro handles the action (e.g. present a sheet, fire a replay) using
    /// its own internal coordinator.
    public static var proDetailActionHandler: (@MainActor @Sendable (String, NetworkEntry) -> Void)? {
        get { storage.lock.withLock { storage.proDetailActionHandler } }
        set { storage.lock.withLock { storage.proDetailActionHandler = newValue } }
    }

    /// Returns the Pro sheet presentation state. The Free detail view
    /// installs `.sheet(isPresented:)` using the binding, and calls
    /// ``ProDetailSheet/content()`` to get the current sheet body.
    ///
    /// When PryPro is not linked this is nil and no sheet modifier is
    /// installed.
    public static var proDetailSheet: (@MainActor @Sendable () -> ProDetailSheet)? {
        get { storage.lock.withLock { storage.proDetailSheet } }
        set { storage.lock.withLock { storage.proDetailSheet = newValue } }
    }

    // MARK: - Pro Rules for Entry

    /// Returns the active rules (breakpoints + mocks) matching a given entry.
    /// The Free detail view renders these inline so the user can toggle/delete
    /// without leaving the detail.
    public static var proRulesForEntry: (@MainActor @Sendable (NetworkEntry) -> [ProEntryRule])? {
        get { storage.lock.withLock { storage.proRulesForEntry } }
        set { storage.lock.withLock { storage.proRulesForEntry = newValue } }
    }

    /// Toggle a rule on/off by its ID.
    public static var proToggleRule: (@MainActor @Sendable (String) -> Void)? {
        get { storage.lock.withLock { storage.proToggleRule } }
        set { storage.lock.withLock { storage.proToggleRule = newValue } }
    }

    /// Delete a rule by its ID.
    public static var proDeleteRule: (@MainActor @Sendable (String) -> Void)? {
        get { storage.lock.withLock { storage.proDeleteRule } }
        set { storage.lock.withLock { storage.proDeleteRule = newValue } }
    }

    // MARK: - Internal Storage

    private static let storage = Storage()

    private final class Storage: @unchecked Sendable {
        let lock = NSLock()
        var binaryBodyDecoder: (@Sendable (Data) -> String?)?
        var proDetailActions: (@MainActor @Sendable (NetworkEntry) -> [ProToolbarAction])?
        var proDetailActionHandler: (@MainActor @Sendable (String, NetworkEntry) -> Void)?
        var proDetailSheet: (@MainActor @Sendable () -> ProDetailSheet)?
        var proRulesForEntry: (@MainActor @Sendable (NetworkEntry) -> [ProEntryRule])?
        var proToggleRule: (@MainActor @Sendable (String) -> Void)?
        var proDeleteRule: (@MainActor @Sendable (String) -> Void)?
    }
}

// MARK: - Pro Toolbar Action Descriptor

/// Describes a single Pro action displayed in the request detail view.
@_spi(PryPro)
public struct ProToolbarAction: Sendable, Identifiable {
    /// Stable identifier for this action (e.g. `"mock"`, `"breakpoint"`).
    public let id: String
    /// Human-readable label shown on the button.
    public let title: String
    /// SF Symbol name for the button icon.
    public let icon: String
    /// Where this action appears in the detail view.
    public let placement: Placement

    @_spi(PryPro)
    public enum Placement: String, Sendable {
        case summary   // Near the status/method in header
        case overview  // In the Overview tab
        case request   // In the Request tab
        case response  // In the Response tab
    }

    public init(id: String, title: String, icon: String, placement: Placement = .overview) {
        self.id = id
        self.title = title
        self.icon = icon
        self.placement = placement
    }
}

// MARK: - Pro Detail Sheet

/// Wrapper returned by the ``PryHooks/proDetailSheet`` hook so the Free
/// view can present Pro sheet content without knowing its concrete type.
///
/// `isPresented` drives the `.sheet` modifier. `content()` is called only
/// when SwiftUI actually presents the sheet, so it always returns the
/// view matching the current action.
@_spi(PryPro)
@MainActor
public struct ProDetailSheet {
    /// Binding that the Free view uses with `.sheet(isPresented:)`.
    public let isPresented: Binding<Bool>
    /// Returns the sheet body for the currently active Pro action.
    public let content: () -> AnyView

    public init(isPresented: Binding<Bool>, content: @escaping () -> AnyView) {
        self.isPresented = isPresented
        self.content = content
    }
}

// MARK: - Pro Entry Rule

/// A rule (breakpoint or mock) that applies to a specific network entry.
@_spi(PryPro)
public struct ProEntryRule: Sendable, Identifiable {
    public let id: String
    public let type: RuleType
    public let title: String
    public let detail: String
    public let isEnabled: Bool

    @_spi(PryPro)
    public enum RuleType: String, Sendable {
        case breakpoint
        case mock
    }

    public init(id: String, type: RuleType, title: String, detail: String, isEnabled: Bool) {
        self.id = id
        self.type = type
        self.title = title
        self.detail = detail
        self.isEnabled = isEnabled
    }
}
