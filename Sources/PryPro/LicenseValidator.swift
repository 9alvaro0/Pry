import Foundation
import CryptoKit

/// Validates Pry Pro license keys offline using Ed25519 signatures.
///
/// License key format: `PRY-{base64_payload}#{base64_signature}`
/// Payload is JSON: `{"email":"...","plan":"pro","exp":"2027-01-01"}`
/// Signed with Ed25519 private key (server-side).
/// Validated with embedded public key (client-side).
enum LicenseValidator {

    /// License validation result.
    enum Result {
        case valid(License)
        case expired(License)
        case invalid
    }

    /// Decoded license info.
    struct License {
        let email: String
        let plan: String
        let expiresAt: Date?
    }

    // MARK: - Public Key

    /// Ed25519 public key for license verification.
    /// Replace this with your actual public key before shipping.
    /// Generate a keypair with: `swift -e "import CryptoKit; let key = Curve25519.Signing.PrivateKey(); print(key.publicKey.rawRepresentation.base64EncodedString())"`
    private static let publicKeyBase64 = "REPLACE_WITH_YOUR_PUBLIC_KEY_BASE64"

    // MARK: - Validation

    /// Validates a license key string.
    /// - Parameter key: The full license key (e.g., `PRY-eyJ...#sig...`)
    /// - Returns: Validation result with decoded license info.
    static func validate(_ key: String) -> Result {
        // Parse key format: PRY-{payload}#{signature}
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("PRY-") else { return .invalid }

        let body = String(trimmed.dropFirst(4))
        let parts = body.split(separator: "#", maxSplits: 1)
        guard parts.count == 2 else { return .invalid }

        let payloadB64 = String(parts[0])
        let signatureB64 = String(parts[1])

        // Decode payload and signature
        guard let payloadData = Data(base64Encoded: payloadB64),
              let signatureData = Data(base64Encoded: signatureB64) else {
            return .invalid
        }

        // Verify signature
        guard verifySignature(payload: payloadData, signature: signatureData) else {
            return .invalid
        }

        // Decode license JSON
        guard let license = decodeLicense(from: payloadData) else {
            return .invalid
        }

        // Check expiration
        if let exp = license.expiresAt, exp < Date() {
            return .expired(license)
        }

        return .valid(license)
    }

    // MARK: - Crypto

    private static func verifySignature(payload: Data, signature: Data) -> Bool {
        guard publicKeyBase64 != "REPLACE_WITH_YOUR_PUBLIC_KEY_BASE64" else {
            // Dev mode: accept any key if public key not configured
            return true
        }

        guard let keyData = Data(base64Encoded: publicKeyBase64) else { return false }

        do {
            let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: keyData)
            return publicKey.isValidSignature(signature, for: payload)
        } catch {
            return false
        }
    }

    // MARK: - Decoding

    private static func decodeLicense(from data: Data) -> License? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        guard let email = json["email"] as? String,
              let plan = json["plan"] as? String else {
            return nil
        }

        // Accept both `2027-01-01` (date only) and `2027-01-01T00:00:00Z` (full timestamp).
        let expiresAt: Date? = (json["exp"] as? String).flatMap { raw -> Date? in
            let fullFormatter = ISO8601DateFormatter()
            fullFormatter.formatOptions = [.withInternetDateTime]
            if let date = fullFormatter.date(from: raw) {
                return date
            }
            let dateOnlyFormatter = ISO8601DateFormatter()
            dateOnlyFormatter.formatOptions = [.withFullDate]
            return dateOnlyFormatter.date(from: raw)
        }

        return License(email: email, plan: plan, expiresAt: expiresAt)
    }
}
