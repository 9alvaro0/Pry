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
    public enum Feature: String, CaseIterable, Sendable {
        case breakpoints
        case mockResponses
        case requestReplay
        case requestDiff
        case sessionExport
        case shareSession
        case networkThrottle
        case protobufDecoder
        case sqliteViewer
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
