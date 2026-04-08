import Foundation

/// Public namespace for Pry library configuration.
///
/// ```swift
/// // Unlock Pro features (after purchase validation)
/// Pry.unlockPro()
///
/// // Check if Pro is active
/// if Pry.isPro { ... }
/// ```
public enum Pry {

    /// Unlock all Pro features. Call this after validating the user's purchase.
    public static func unlockPro() {
        FeatureGate.unlockPro()
    }

    /// Lock back to free tier.
    public static func lockToFree() {
        FeatureGate.lockToFree()
    }

    /// Whether Pro features are currently unlocked.
    public static var isPro: Bool {
        FeatureGate.isProUnlocked
    }
}
