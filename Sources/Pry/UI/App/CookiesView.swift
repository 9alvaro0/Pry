import SwiftUI
import UIKit

struct CookiesView: View {
    @State private var cookies: [HTTPCookie] = []
    @State private var searchText = ""

    private var filteredCookies: [HTTPCookie] {
        guard !searchText.isEmpty else { return cookies }
        let query = searchText.lowercased()
        return cookies.filter {
            $0.name.lowercased().contains(query) ||
            $0.domain.lowercased().contains(query) ||
            $0.value.lowercased().contains(query)
        }
    }

    // Group by domain
    private var groupedCookies: [(domain: String, cookies: [HTTPCookie])] {
        let grouped = Dictionary(grouping: filteredCookies, by: { $0.domain })
        return grouped.sorted { $0.key < $1.key }.map { (domain: $0.key, cookies: $0.value.sorted { $0.name < $1.name }) }
    }

    var body: some View {
        Group {
            if cookies.isEmpty {
                ContentUnavailableView {
                    Label("No Cookies", systemImage: "birthday.cake")
                } description: {
                    Text("No HTTP cookies stored")
                }
            } else {
                List {
                    ForEach(groupedCookies, id: \.domain) { group in
                        Section {
                            ForEach(group.cookies, id: \.name) { cookie in
                                NavigationLink {
                                    CookieDetailView(cookie: cookie)
                                } label: {
                                    cookieRow(cookie)
                                }
                                .listRowBackground(PryTheme.Colors.surface)
                            }
                        } header: {
                            Text(group.domain)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .pryBackground()
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Name, domain, value...")
        .onAppear { loadCookies() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { loadCookies() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.textSecondary)
                }
            }
        }
    }

    private func cookieRow(_ cookie: HTTPCookie) -> some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            Text(cookie.name)
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)

            Text(cookie.value)
                .font(PryTheme.Typography.codeSmall)
                .foregroundStyle(PryTheme.Colors.textTertiary)
                .lineLimit(1)

            HStack(spacing: PryTheme.Spacing.sm) {
                if cookie.isSecure {
                    Text("Secure")
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.success)
                }
                if cookie.isHTTPOnly {
                    Text("HttpOnly")
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.accent)
                }
                if let expires = cookie.expiresDate {
                    Text(expires < Date() ? "Expired" : expires.relativeTimestamp)
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(expires < Date() ? PryTheme.Colors.error : PryTheme.Colors.textTertiary)
                } else {
                    Text("Session")
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }
            }
        }
        .padding(.vertical, PryTheme.Spacing.xs)
    }

    private func loadCookies() {
        cookies = HTTPCookieStorage.shared.cookies ?? []
    }
}

// MARK: - Cookie Detail

struct CookieDetailView: View {
    let cookie: HTTPCookie

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Value (copyable)
                DetailSectionView(title: "Value") {
                    Text(cookie.value)
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                        .textSelection(.enabled)
                        .padding(PryTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PryTheme.Colors.surface)
                        .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                }

                DetailSectionView(title: "Properties") {
                    VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                        DetailRowView(label: "Name", value: cookie.name)
                        DetailRowView(label: "Domain", value: cookie.domain)
                        DetailRowView(label: "Path", value: cookie.path)
                        DetailRowView(label: "Secure", value: cookie.isSecure ? "Yes" : "No")
                        DetailRowView(label: "HttpOnly", value: cookie.isHTTPOnly ? "Yes" : "No")
                        if let expires = cookie.expiresDate {
                            DetailRowView(label: "Expires", value: expires.formatFullTimestamp())
                        } else {
                            DetailRowView(label: "Expires", value: "Session (no expiry)")
                        }
                        if let comment = cookie.comment {
                            DetailRowView(label: "Comment", value: comment)
                        }
                    }
                }
            }
            .padding(.horizontal, PryTheme.Spacing.lg)
        }
        .pryBackground()
        .navigationTitle(cookie.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CopyButtonView(valueToCopy: "\(cookie.name)=\(cookie.value)")
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Cookies") {
    NavigationStack {
        CookiesView()
            .navigationTitle("Cookies")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
