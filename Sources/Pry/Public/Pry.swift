import Foundation

/// Public namespace for Pry library configuration.
///
/// ```swift
/// // Activate Pro with a license key
/// let result = Pry.activate("PRY-eyJ...#sig...")
///
/// // Check status
/// if Pry.isPro { ... }
///
/// // Manual unlock (for custom purchase flows)
/// Pry.unlockPro()
/// ```
public enum Pry {

    /// Result of a license activation attempt.
    public enum ActivationResult: Sendable {
        /// License is valid and Pro features are unlocked.
        case activated(email: String)
        /// License key has expired.
        case expired(email: String)
        /// License key is invalid or malformed.
        case invalid
    }

    // MARK: - License Activation

    /// Activate Pro features with a license key.
    ///
    /// The key is validated offline using Ed25519 signature verification.
    /// If valid, Pro is unlocked and the key is persisted for future launches.
    ///
    /// ```swift
    /// switch Pry.activate("PRY-eyJ...#sig...") {
    /// case .activated(let email):
    ///     print("Pro activated for \(email)")
    /// case .expired:
    ///     print("License expired")
    /// case .invalid:
    ///     print("Invalid key")
    /// }
    /// ```
    ///
    /// - Parameter key: The license key string (format: `PRY-{payload}#{signature}`)
    /// - Returns: The activation result.
    @discardableResult
    public static func activate(_ key: String) -> ActivationResult {
        let result = LicenseValidator.validate(key)

        switch result {
        case .valid(let license):
            FeatureGate.unlockPro()
            persistLicenseKey(key)
            return .activated(email: license.email)

        case .expired(let license):
            FeatureGate.lockToFree()
            clearLicenseKey()
            return .expired(email: license.email)

        case .invalid:
            FeatureGate.lockToFree()
            clearLicenseKey()
            return .invalid
        }
    }

    /// Deactivate Pro and remove the stored license key.
    public static func deactivate() {
        FeatureGate.lockToFree()
        clearLicenseKey()
    }

    // MARK: - Manual Unlock (no license key)

    /// Unlock all Pro features without a license key.
    ///
    /// Use this if you handle purchase validation yourself
    /// (e.g., StoreKit, RevenueCat, or server-side validation).
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

    // MARK: - Auto-restore

    /// Restores Pro if a valid license key was previously activated.
    ///
    /// Call this at app launch to auto-restore Pro status:
    /// ```swift
    /// Pry.restoreIfNeeded()
    /// ```
    @discardableResult
    public static func restoreIfNeeded() -> ActivationResult? {
        guard let key = storedLicenseKey() else { return nil }
        return activate(key)
    }

    // MARK: - Persistence

    private static let licenseKeyKey = "pry_license_key"

    private static func persistLicenseKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: licenseKeyKey)
    }

    private static func clearLicenseKey() {
        UserDefaults.standard.removeObject(forKey: licenseKeyKey)
    }

    private static func storedLicenseKey() -> String? {
        UserDefaults.standard.string(forKey: licenseKeyKey)
    }
}
