import Foundation

/// Decodes JWT tokens without external dependencies.
enum JWTDecoder {

    struct DecodedJWT {
        let header: [String: Any]
        let payload: [String: Any]
        let isExpired: Bool
        let expiresAt: Date?
        let issuedAt: Date?
        let issuer: String?
        let subject: String?
        let timeRemaining: TimeInterval?
    }

    /// Attempts to decode a JWT token string. Returns nil if not a valid JWT.
    static func decode(_ token: String) -> DecodedJWT? {
        // Strip "Bearer " prefix if present
        let raw = token.hasPrefix("Bearer ") ? String(token.dropFirst(7)) : token

        let parts = raw.components(separatedBy: ".")
        guard parts.count == 3 else { return nil }

        guard let headerData = base64URLDecode(parts[0]),
              let payloadData = base64URLDecode(parts[1]),
              let header = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any],
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
        else { return nil }

        // Extract standard claims
        let exp = (payload["exp"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue) }
        let iat = (payload["iat"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue) }
        let iss = payload["iss"] as? String
        let sub = payload["sub"] as? String

        let now = Date()
        let isExpired = exp.map { $0 < now } ?? false
        let timeRemaining = exp.map { $0.timeIntervalSince(now) }

        return DecodedJWT(
            header: header,
            payload: payload,
            isExpired: isExpired,
            expiresAt: exp,
            issuedAt: iat,
            issuer: iss,
            subject: sub,
            timeRemaining: timeRemaining
        )
    }

    /// Decodes base64url-encoded string (JWT uses URL-safe base64 without padding).
    private static func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        return Data(base64Encoded: base64)
    }
}
