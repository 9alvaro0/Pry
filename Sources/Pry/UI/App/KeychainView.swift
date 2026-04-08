import SwiftUI
import Security
import UIKit

// MARK: - Model

private struct KeychainItem: Identifiable {
    let id = UUID()
    let itemClass: String
    let account: String?
    let service: String?
    let label: String?
    let server: String?
    let data: String?
    let accessGroup: String?
    let createdAt: Date?
    let modifiedAt: Date?

    var displayName: String {
        account ?? service ?? label ?? server ?? "Unknown"
    }
}

// MARK: - View

struct KeychainView: View {
    private static let keychainClasses: [(cfString: CFString, name: String)] = [
        (kSecClassGenericPassword, "Generic Password"),
        (kSecClassInternetPassword, "Internet Password"),
        (kSecClassCertificate, "Certificate"),
        (kSecClassKey, "Key"),
    ]

    @State private var items: [KeychainItem] = []
    @State private var searchText = ""
    @State private var errorMessage: String?

    private var filteredItems: [KeychainItem] {
        guard !searchText.isEmpty else { return items }
        let query = searchText.lowercased()
        return items.filter {
            ($0.account?.lowercased().contains(query) ?? false) ||
            ($0.service?.lowercased().contains(query) ?? false) ||
            ($0.label?.lowercased().contains(query) ?? false) ||
            ($0.server?.lowercased().contains(query) ?? false)
        }
    }

    private var groupedItems: [(className: String, items: [KeychainItem])] {
        let grouped = Dictionary(grouping: filteredItems, by: { $0.itemClass })
        let order = ["Generic Password", "Internet Password", "Certificate", "Key"]
        return order.compactMap { className in
            guard let group = grouped[className], !group.isEmpty else { return nil }
            return (className: className, items: group.sorted { $0.displayName < $1.displayName })
        }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(groupedItems, id: \.className) { group in
                        Section {
                            ForEach(group.items) { item in
                                NavigationLink {
                                    KeychainItemDetailView(item: item)
                                } label: {
                                    keychainRow(item)
                                }
                                .listRowBackground(PryTheme.Colors.surface)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteItem(item)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                        } header: {
                            Text(pluralClassName(group.className))
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .pryBackground()
        .searchable(text: $searchText, prompt: "Account, service, label...")
        .onAppear { loadItems() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { loadItems() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Keychain Items", systemImage: "key")
        } description: {
            if let errorMessage {
                Text(errorMessage)
            } else {
                Text("No accessible keychain items found")
            }
        }
    }

    // MARK: - Row

    private func keychainRow(_ item: KeychainItem) -> some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
            Text(item.displayName)
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .lineLimit(1)

            if let subtitle = rowSubtitle(for: item) {
                Text(subtitle)
                    .font(PryTheme.Typography.codeSmall)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
                    .lineLimit(1)
            }

            HStack(spacing: PryTheme.Spacing.sm) {
                Text(item.itemClass)
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(classColor(item.itemClass))

                if let created = item.createdAt {
                    Text(created.relativeTimestamp)
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }
            }
        }
        .padding(.vertical, PryTheme.Spacing.xs)
    }

    private func rowSubtitle(for item: KeychainItem) -> String? {
        if let service = item.service, item.account != nil {
            return service
        }
        if let server = item.server {
            return server
        }
        if let label = item.label, item.account != nil || item.service != nil {
            return label
        }
        return nil
    }

    private func classColor(_ className: String) -> Color {
        switch className {
        case "Generic Password": return PryTheme.Colors.accent
        case "Internet Password": return PryTheme.Colors.success
        case "Certificate": return PryTheme.Colors.warning
        case "Key": return PryTheme.Colors.syntaxBool
        default: return PryTheme.Colors.textTertiary
        }
    }

    private func pluralClassName(_ className: String) -> String {
        switch className {
        case "Generic Password": return "Generic Passwords"
        case "Internet Password": return "Internet Passwords"
        case "Certificate": return "Certificates"
        case "Key": return "Keys"
        default: return className
        }
    }

    // MARK: - Data Loading

    private func loadItems() {
        var allItems: [KeychainItem] = []
        errorMessage = nil

        for (secClass, className) in Self.keychainClasses {
            let query: [String: Any] = [
                kSecClass as String: secClass,
                kSecReturnAttributes as String: true,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitAll,
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            if status == errSecSuccess, let entries = result as? [[String: Any]] {
                for entry in entries {
                    let item = parseKeychainEntry(entry, className: className)
                    allItems.append(item)
                }
            } else if status != errSecItemNotFound {
                errorMessage = "Some items could not be read (status: \(status))"
            }
        }

        items = allItems
    }

    private func parseKeychainEntry(_ entry: [String: Any], className: String) -> KeychainItem {
        let account = entry[kSecAttrAccount as String] as? String
        let service = entry[kSecAttrService as String] as? String
        let label = entry[kSecAttrLabel as String] as? String
        let server = entry[kSecAttrServer as String] as? String
        let accessGroup = entry[kSecAttrAccessGroup as String] as? String
        let createdAt = entry[kSecAttrCreationDate as String] as? Date
        let modifiedAt = entry[kSecAttrModificationDate as String] as? Date

        var dataString: String?
        if let data = entry[kSecValueData as String] as? Data {
            if let utf8 = String(data: data, encoding: .utf8), !utf8.isEmpty {
                dataString = utf8
            } else {
                dataString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
            }
        }

        return KeychainItem(
            itemClass: className,
            account: account,
            service: service,
            label: label,
            server: server,
            data: dataString,
            accessGroup: accessGroup,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }

    // MARK: - Delete

    private func deleteItem(_ item: KeychainItem) {
        var query: [String: Any] = [:]

        guard let match = Self.keychainClasses.first(where: { $0.name == item.itemClass }) else { return }
        query[kSecClass as String] = match.cfString

        if let account = item.account {
            query[kSecAttrAccount as String] = account
        }
        if let service = item.service {
            query[kSecAttrService as String] = service
        }
        if let server = item.server {
            query[kSecAttrServer as String] = server
        }
        if let label = item.label {
            query[kSecAttrLabel as String] = label
        }

        SecItemDelete(query as CFDictionary)
        loadItems()
    }
}

// MARK: - Detail View

private struct KeychainItemDetailView: View {
    let item: KeychainItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let data = item.data {
                    DetailSectionView(title: "Value") {
                        Text(data)
                            .font(PryTheme.Typography.code)
                            .foregroundStyle(PryTheme.Colors.textPrimary)
                            .textSelection(.enabled)
                            .padding(PryTheme.Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(PryTheme.Colors.surface)
                            .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
                    }
                }

                DetailSectionView(title: "Attributes") {
                    VStack(alignment: .leading, spacing: PryTheme.Spacing.xs) {
                        DetailRowView(label: "Class", value: item.itemClass)

                        if let account = item.account {
                            DetailRowView(label: "Account", value: account)
                        }
                        if let service = item.service {
                            DetailRowView(label: "Service", value: service)
                        }
                        if let label = item.label {
                            DetailRowView(label: "Label", value: label)
                        }
                        if let server = item.server {
                            DetailRowView(label: "Server", value: server)
                        }
                        if let accessGroup = item.accessGroup {
                            DetailRowView(label: "Access Group", value: accessGroup)
                        }
                        if let created = item.createdAt {
                            DetailRowView(label: "Created", value: created.formatFullTimestamp())
                        }
                        if let modified = item.modifiedAt {
                            DetailRowView(label: "Modified", value: modified.formatFullTimestamp())
                        }
                    }
                }
            }
            .padding(.horizontal, PryTheme.Spacing.lg)
        }
        .pryBackground()
        .navigationTitle(item.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let data = item.data {
                    CopyButtonView(valueToCopy: data)
                }
            }
        }
    }
}
