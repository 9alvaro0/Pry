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
                                .listRowBackground(InspectorTheme.Colors.surface)
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
        .inspectorBackground()
        .searchable(text: $searchText, prompt: "Name, domain, value...")
        .onAppear { loadCookies() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { loadCookies() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(InspectorTheme.Colors.textSecondary)
                }
            }
        }
    }

    private func cookieRow(_ cookie: HTTPCookie) -> some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
            Text(cookie.name)
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)

            Text(cookie.value)
                .font(InspectorTheme.Typography.codeSmall)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
                .lineLimit(1)

            HStack(spacing: InspectorTheme.Spacing.sm) {
                if cookie.isSecure {
                    Text("Secure")
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.success)
                }
                if cookie.isHTTPOnly {
                    Text("HttpOnly")
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.accent)
                }
                if let expires = cookie.expiresDate {
                    Text(expires < Date() ? "Expired" : expires.relativeTimestamp)
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(expires < Date() ? InspectorTheme.Colors.error : InspectorTheme.Colors.textTertiary)
                } else {
                    Text("Session")
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }
            }
        }
        .padding(.vertical, InspectorTheme.Spacing.xs)
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
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.textPrimary)
                        .textSelection(.enabled)
                        .padding(InspectorTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(InspectorTheme.Colors.surface)
                        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                }

                DetailSectionView(title: "Properties") {
                    VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xs) {
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
            .padding(.horizontal, InspectorTheme.Spacing.lg)
        }
        .inspectorBackground()
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
