import Foundation

/// Controls which features are available based on the license tier.
///
/// The SDK consumer unlocks Pro features by calling:
/// ```swift
/// Pry.unlockPro()
/// ```
///
/// The gate does NOT handle purchases or license validation.
/// That's the consumer's responsibility.
public enum FeatureGate {

    /// All gated features.
    /// All gated features available in the Pro tier.
    public enum Feature: String, CaseIterable, Sendable {
        /// Pause and edit requests before they are sent.
        case breakpoints
        /// Return custom responses instead of hitting the network.
        case mockResponses
        /// Replay a previously captured request.
        case requestReplay
        /// Compare two captured requests side by side.
        case requestDiff
        /// Export the current session to a file.
        case sessionExport
        /// Share a session with another developer.
        case shareSession
        /// Simulate slow or lossy network conditions.
        case networkThrottle
        /// Decode Protocol Buffer payloads.
        case protobufDecoder
        /// Browse local SQLite databases.
        case sqliteViewer
        /// View CPU, memory, and frame rate metrics.
        case performanceMetrics
    }

    /// Current tier. Defaults to free.
    nonisolated(unsafe) private static var tier: Tier = .free

    enum Tier {
        case free
        case pro
    }

    /// Features available in the free tier.
    private static let freeFeatures: Set<Feature> = [
        // Core inspection is always free
    ]

    // MARK: - Public API

    /// Check if a feature is available in the current tier.
    public static func isAvailable(_ feature: Feature) -> Bool {
        tier == .pro || freeFeatures.contains(feature)
    }

    /// Unlock all Pro features.
    public static func unlockPro() {
        tier = .pro
    }

    /// Lock back to free tier.
    public static func lockToFree() {
        tier = .free
    }

    /// Whether Pro is currently unlocked.
    public static var isProUnlocked: Bool {
        tier == .pro
    }
}
