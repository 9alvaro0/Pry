import SwiftUI

/// Displays decoded JWT token information with claims, expiration status, and payload.
struct JWTDetailView: View {
    let token: String

    private var decoded: JWTDecoder.DecodedJWT? {
        JWTDecoder.decode(token)
    }

    var body: some View {
        if let jwt = decoded {
            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.md) {
                // Expiration status
                expirationBadge(jwt)

                // Standard claims
                if jwt.issuer != nil || jwt.subject != nil || jwt.issuedAt != nil {
                    claimsSection(jwt)
                }

                // Full payload
                payloadSection(jwt)
            }
        }
    }

    // MARK: - Expiration

    private func expirationBadge(_ jwt: JWTDecoder.DecodedJWT) -> some View {
        HStack(spacing: InspectorTheme.Spacing.sm) {
            if jwt.isExpired {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(InspectorTheme.Typography.detail)
                Text("Expired")
                    .font(InspectorTheme.Typography.detail)
                    .fontWeight(.semibold)
                if let exp = jwt.expiresAt {
                    Text(exp.relativeTimestamp)
                        .font(InspectorTheme.Typography.detail)
                }
            } else if let remaining = jwt.timeRemaining {
                Image(systemName: "clock")
                    .font(InspectorTheme.Typography.detail)
                Text("Expires in \(formatRemaining(remaining))")
                    .font(InspectorTheme.Typography.detail)
                    .fontWeight(.semibold)
            } else {
                Image(systemName: "checkmark.circle")
                    .font(InspectorTheme.Typography.detail)
                Text("No expiration")
                    .font(InspectorTheme.Typography.detail)
            }
        }
        .foregroundStyle(jwt.isExpired ? InspectorTheme.Colors.error : InspectorTheme.Colors.success)
        .padding(.horizontal, InspectorTheme.Spacing.sm)
        .padding(.vertical, InspectorTheme.Spacing.xs)
        .background(
            (jwt.isExpired ? InspectorTheme.Colors.error : InspectorTheme.Colors.success).opacity(InspectorTheme.Opacity.tint)
        )
        .clipShape(.capsule)
    }

    // MARK: - Claims

    private func claimsSection(_ jwt: JWTDecoder.DecodedJWT) -> some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
            if let iss = jwt.issuer {
                DetailRowView(label: "Issuer", value: iss)
            }
            if let sub = jwt.subject {
                DetailRowView(label: "Subject", value: sub)
            }
            if let iat = jwt.issuedAt {
                DetailRowView(label: "Issued At", value: iat.formatFullTimestamp())
            }
            if let exp = jwt.expiresAt {
                DetailRowView(label: "Expires At", value: exp.formatFullTimestamp())
            }
        }
    }

    // MARK: - Payload

    private func payloadSection(_ jwt: JWTDecoder.DecodedJWT) -> some View {
        Group {
            if let jsonData = try? JSONSerialization.data(withJSONObject: jwt.payload, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                CodeBlockView(text: jsonString, language: .json)
            }
        }
    }

    // MARK: - Helpers

    private func formatRemaining(_ interval: TimeInterval) -> String {
        if interval < 60 { return "\(Int(interval))s" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        return "\(Int(interval / 86400))d"
    }
}

// MARK: - Previews

#if DEBUG
#Preview("JWT - Valid") {
    // eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiaXNzIjoiYXV0aC5leGFtcGxlLmNvbSIsImlhdCI6MTcxMjUwMDAwMCwiZXhwIjo5OTk5OTk5OTk5fQ.signature
    let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiaXNzIjoiYXV0aC5leGFtcGxlLmNvbSIsImlhdCI6MTcxMjUwMDAwMCwiZXhwIjo5OTk5OTk5OTk5fQ.signature"

    ScrollView {
        JWTDetailView(token: token)
            .padding()
    }
    .inspectorBackground()
}

#Preview("JWT - Expired") {
    // exp in the past
    let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyMTIzIiwiaXNzIjoiYXBpLmV4YW1wbGUuY29tIiwiaWF0IjoxNzEyNTAwMDAwLCJleHAiOjE3MTI1MDAwMDF9.signature"

    ScrollView {
        JWTDetailView(token: token)
            .padding()
    }
    .inspectorBackground()
}
#endif
