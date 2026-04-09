import Foundation
import Testing
@testable import Pry

@Suite("LicenseValidator")
struct LicenseValidatorTests {

    // MARK: - Helpers

    /// Builds a license key in the format `PRY-{base64 payload}#{base64 signature}`.
    /// The signature content doesn't need to be cryptographically valid while the
    /// embedded public key placeholder is set — `verifySignature` short-circuits
    /// to `true` in dev mode. See `LicenseValidator.verifySignature`.
    private func makeKey(payloadJSON: String, signature: String = "AA==") -> String {
        let payloadData = payloadJSON.data(using: .utf8) ?? Data()
        let payloadB64 = payloadData.base64EncodedString()
        return "PRY-\(payloadB64)#\(signature)"
    }

    private func isoDateString(daysFromNow: Int) -> String {
        let formatter = ISO8601DateFormatter()
        let date = Date().addingTimeInterval(TimeInterval(daysFromNow * 86_400))
        return formatter.string(from: date)
    }

    // MARK: - Invalid Format Rejection

    @Test("Rejects empty string")
    func rejectsEmptyString() {
        if case .invalid = LicenseValidator.validate("") { return }
        Issue.record("Expected .invalid for empty string")
    }

    @Test("Rejects key without PRY- prefix")
    func rejectsMissingPrefix() {
        let key = "eyJlbWFpbCI6ImFAYi5jb20iLCJwbGFuIjoicHJvIn0=#AA=="
        if case .invalid = LicenseValidator.validate(key) { return }
        Issue.record("Expected .invalid for missing PRY- prefix")
    }

    @Test("Rejects key without # separator")
    func rejectsMissingSeparator() {
        // Valid base64 payload, but no "#signature" part.
        let payloadB64 = "eyJlbWFpbCI6ImFAYi5jb20iLCJwbGFuIjoicHJvIn0=".replacingOccurrences(of: "#", with: "")
        let key = "PRY-\(payloadB64)"
        if case .invalid = LicenseValidator.validate(key) { return }
        Issue.record("Expected .invalid for missing # separator")
    }

    @Test("Rejects corrupted base64 payload")
    func rejectsCorruptedPayload() {
        let key = "PRY-!!not_base64!!#AA=="
        if case .invalid = LicenseValidator.validate(key) { return }
        Issue.record("Expected .invalid for corrupted base64 payload")
    }

    @Test("Rejects corrupted base64 signature")
    func rejectsCorruptedSignature() {
        let payload = #"{"email":"a@b.com","plan":"pro"}"#
        let payloadB64 = payload.data(using: .utf8)!.base64EncodedString()
        let key = "PRY-\(payloadB64)#!!not_base64!!"
        if case .invalid = LicenseValidator.validate(key) { return }
        Issue.record("Expected .invalid for corrupted signature")
    }

    @Test("Rejects payload that is not a JSON object")
    func rejectsNonJSONPayload() {
        let payloadB64 = "not valid json".data(using: .utf8)!.base64EncodedString()
        let key = "PRY-\(payloadB64)#AA=="
        if case .invalid = LicenseValidator.validate(key) { return }
        Issue.record("Expected .invalid for non-JSON payload")
    }

    @Test("Rejects payload missing required email field")
    func rejectsPayloadWithoutEmail() {
        let key = makeKey(payloadJSON: #"{"plan":"pro"}"#)
        if case .invalid = LicenseValidator.validate(key) { return }
        Issue.record("Expected .invalid for payload without email")
    }

    @Test("Rejects payload missing required plan field")
    func rejectsPayloadWithoutPlan() {
        let key = makeKey(payloadJSON: #"{"email":"a@b.com"}"#)
        if case .invalid = LicenseValidator.validate(key) { return }
        Issue.record("Expected .invalid for payload without plan")
    }

    // MARK: - Whitespace

    @Test("Accepts leading and trailing whitespace")
    func trimsWhitespace() {
        let key = makeKey(payloadJSON: #"{"email":"a@b.com","plan":"pro"}"#)
        let padded = "   \n\(key)\n   "
        if case .valid = LicenseValidator.validate(padded) { return }
        Issue.record("Expected .valid for whitespace-padded key")
    }

    // MARK: - Happy Path (Dev Mode)

    // Note: the tests below rely on the fact that the bundled public key is
    // still the placeholder `REPLACE_WITH_YOUR_PUBLIC_KEY_BASE64`, so signature
    // verification accepts any signature. If a real key is ever wired in, these
    // tests will need to be regenerated against valid signed payloads.

    @Test("Accepts a minimal valid payload")
    func acceptsMinimalValidPayload() {
        let key = makeKey(payloadJSON: #"{"email":"alvaro@example.com","plan":"pro"}"#)
        guard case let .valid(license) = LicenseValidator.validate(key) else {
            Issue.record("Expected .valid for minimal payload")
            return
        }
        #expect(license.email == "alvaro@example.com")
        #expect(license.plan == "pro")
        #expect(license.expiresAt == nil)
    }

    @Test("Accepts a future-dated license as .valid")
    func acceptsFutureExpiry() {
        let exp = isoDateString(daysFromNow: 365)
        let key = makeKey(payloadJSON: #"{"email":"a@b.com","plan":"pro","exp":"\#(exp)"}"#)
        guard case let .valid(license) = LicenseValidator.validate(key) else {
            Issue.record("Expected .valid for future-dated license")
            return
        }
        #expect(license.expiresAt != nil)
        #expect(license.expiresAt! > Date())
    }

    @Test("Reports .expired for past-dated license")
    func reportsExpiredForPastDate() {
        let exp = isoDateString(daysFromNow: -30)
        let key = makeKey(payloadJSON: #"{"email":"a@b.com","plan":"pro","exp":"\#(exp)"}"#)
        guard case let .expired(license) = LicenseValidator.validate(key) else {
            Issue.record("Expected .expired for past-dated license")
            return
        }
        #expect(license.email == "a@b.com")
        #expect(license.plan == "pro")
        #expect(license.expiresAt != nil)
        #expect(license.expiresAt! < Date())
    }

    @Test("Treats unparseable exp string as no expiration")
    func unparseableExpIsIgnored() {
        let key = makeKey(payloadJSON: #"{"email":"a@b.com","plan":"pro","exp":"tomorrow"}"#)
        guard case let .valid(license) = LicenseValidator.validate(key) else {
            Issue.record("Expected .valid when exp is unparseable")
            return
        }
        #expect(license.expiresAt == nil)
    }

    @Test("Different plan strings are preserved verbatim")
    func preservesPlanString() {
        let key = makeKey(payloadJSON: #"{"email":"a@b.com","plan":"team-annual"}"#)
        guard case let .valid(license) = LicenseValidator.validate(key) else {
            Issue.record("Expected .valid")
            return
        }
        #expect(license.plan == "team-annual")
    }

    // MARK: - Parameterized invalid inputs

    @Test(
        "Rejects a variety of malformed license strings",
        arguments: [
            "",
            " ",
            "not a license at all",
            "PRY-",
            "PRY-#",
            "PRY-no_hash_separator",
            "prefix-PRY-abc#def",
        ]
    )
    func rejectsMalformedKeys(_ key: String) {
        if case .invalid = LicenseValidator.validate(key) { return }
        Issue.record("Expected .invalid for: '\(key)'")
    }
}
