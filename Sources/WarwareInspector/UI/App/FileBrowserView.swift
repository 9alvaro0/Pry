import SwiftUI
import UIKit

// MARK: - File Item Model

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64
    let modifiedDate: Date?
    let createdDate: Date?
    let itemCount: Int?

    var icon: String {
        if isDirectory { return "folder.fill" }
        if isImage { return "photo" }
        if isSQLite { return "cylinder" }
        if isPlist { return "list.bullet" }
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "json": return "curlybraces"
        case "txt", "log", "csv": return "doc.text"
        case "db-shm", "db-wal", "db-journal": return "cylinder"
        default:
            if isTextReadable { return "doc.text" }
            return "doc"
        }
    }

    var iconColor: Color {
        if isDirectory { return .blue }
        if isImage { return .green }
        if isSQLite { return .purple }
        if isPlist { return .orange }
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "json": return .yellow
        case "db-shm", "db-wal", "db-journal": return .purple
        case "txt", "log", "csv": return .gray
        default: return .gray
        }
    }

    var isImage: Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "gif", "webp", "heic"].contains(ext) { return true }
        // Check magic bytes for files without extension (e.g. Kingfisher cache)
        return Self.isImageByMagicBytes(path: path)
    }

    static func isImageByMagicBytes(path: String) -> Bool {
        guard let handle = FileHandle(forReadingAtPath: path) else { return false }
        defer { handle.closeFile() }
        let data = handle.readData(ofLength: 4)
        guard data.count >= 3 else { return false }
        let bytes = [UInt8](data)
        return bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) || // PNG
               bytes.starts(with: [0xFF, 0xD8, 0xFF]) ||        // JPEG
               bytes.starts(with: [0x47, 0x49, 0x46]) ||        // GIF
               bytes.starts(with: [0x52, 0x49, 0x46, 0x46])     // WebP
    }

    var isTextReadable: Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        if ["json", "plist", "txt", "log", "csv", "xml", "html", "css", "js", "swift", "m", "h", "strings", "yaml", "yml", "md"].contains(ext) { return true }
        // Check content for files without extension
        return Self.isTextByContent(path: path)
    }

    var isSQLite: Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        if ["sqlite", "db", "sqlite3"].contains(ext) { return true }
        return Self.isSQLiteByMagicBytes(path: path)
    }

    var isPlist: Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        if ext == "plist" { return true }
        return Self.isPlistByContent(path: path)
    }

    static func isTextByContent(path: String) -> Bool {
        guard let handle = FileHandle(forReadingAtPath: path) else { return false }
        defer { handle.closeFile() }
        let data = handle.readData(ofLength: 256)
        guard let str = String(data: data, encoding: .utf8) else { return false }
        let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("{") || trimmed.hasPrefix("[") || trimmed.hasPrefix("<") || trimmed.allSatisfy { $0.isASCII }
    }

    static func isSQLiteByMagicBytes(path: String) -> Bool {
        guard let handle = FileHandle(forReadingAtPath: path) else { return false }
        defer { handle.closeFile() }
        let data = handle.readData(ofLength: 16)
        guard let header = String(data: data, encoding: .utf8) else { return false }
        return header.hasPrefix("SQLite format 3")
    }

    static func isPlistByContent(path: String) -> Bool {
        guard let handle = FileHandle(forReadingAtPath: path) else { return false }
        defer { handle.closeFile() }
        let data = handle.readData(ofLength: 8)
        let bytes = [UInt8](data)
        // Binary plist magic: "bplist"
        return bytes.starts(with: [0x62, 0x70, 0x6C, 0x69, 0x73, 0x74])
    }
}

// MARK: - File System Helper

private enum FileSystemHelper {

    static func loadItems(at path: String) -> [FileItem] {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: path) else { return [] }

        var items: [FileItem] = []
        for name in names where !name.hasPrefix(".") {
            let fullPath = (path as NSString).appendingPathComponent(name)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: fullPath, isDirectory: &isDir) else { continue }

            let attrs = try? fm.attributesOfItem(atPath: fullPath)
            let size: Int64
            let itemCount: Int?

            if isDir.boolValue {
                size = directorySize(at: fullPath, depth: 0, maxDepth: 2)
                itemCount = (try? fm.contentsOfDirectory(atPath: fullPath))?.count
            } else {
                size = (attrs?[.size] as? Int64) ?? 0
                itemCount = nil
            }

            items.append(FileItem(
                name: name,
                path: fullPath,
                isDirectory: isDir.boolValue,
                size: size,
                modifiedDate: attrs?[.modificationDate] as? Date,
                createdDate: attrs?[.creationDate] as? Date,
                itemCount: itemCount
            ))
        }

        // Folders first, then files, both sorted by name
        let folders = items.filter(\.isDirectory).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let files = items.filter { !$0.isDirectory }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return folders + files
    }

    static func directorySize(at path: String, depth: Int, maxDepth: Int) -> Int64 {
        guard depth < maxDepth else { return 0 }
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: path) else { return 0 }

        var total: Int64 = 0
        for name in names {
            let fullPath = (path as NSString).appendingPathComponent(name)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: fullPath, isDirectory: &isDir) else { continue }

            if isDir.boolValue {
                total += directorySize(at: fullPath, depth: depth + 1, maxDepth: maxDepth)
            } else {
                let attrs = try? fm.attributesOfItem(atPath: fullPath)
                total += (attrs?[.size] as? Int64) ?? 0
            }
        }
        return total
    }

    static func formattedSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    static func formattedDate(_ date: Date?) -> String {
        guard let date else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func shortDate(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Sandbox Root Folder

private struct SandboxFolder: Identifiable {
    let id = UUID()
    let name: String
    let relativePath: String
    let icon: String

    var fullPath: String {
        (NSHomeDirectory() as NSString).appendingPathComponent(relativePath)
    }
}

// MARK: - File Browser View

struct FileBrowserView: View {
    let path: String
    let title: String

    init(path: String = NSHomeDirectory(), title: String = "Sandbox") {
        self.path = path
        self.title = title
    }

    @State private var items: [FileItem] = []
    @State private var isLoading = true

    private var isRoot: Bool { path == NSHomeDirectory() }

    private let sandboxFolders: [SandboxFolder] = [
        SandboxFolder(name: "Documents", relativePath: "Documents", icon: "doc.fill"),
        SandboxFolder(name: "Library", relativePath: "Library", icon: "books.vertical.fill"),
        SandboxFolder(name: "Caches", relativePath: "Library/Caches", icon: "archivebox.fill"),
        SandboxFolder(name: "tmp", relativePath: "tmp", icon: "clock.fill"),
    ]

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .tint(InspectorTheme.Colors.textSecondary)
                    .padding(.top, 60)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    if isRoot {
                        rootCards
                            .padding(.bottom, InspectorTheme.Spacing.xl)

                        sectionHeader("All Contents")
                    }

                    directoryList
                }
                .padding(.horizontal, InspectorTheme.Spacing.lg)
                .padding(.top, InspectorTheme.Spacing.sm)
                .padding(.bottom, InspectorTheme.Spacing.xl)
            }
        }
        .inspectorBackground()
        .task {
            items = FileSystemHelper.loadItems(at: path)
            isLoading = false
        }
    }

    // MARK: - Root Cards

    private var rootCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: InspectorTheme.Spacing.sm),
            GridItem(.flexible(), spacing: InspectorTheme.Spacing.sm),
        ], spacing: InspectorTheme.Spacing.sm) {
            ForEach(sandboxFolders) { folder in
                NavigationLink {
                    FileBrowserView(path: folder.fullPath, title: folder.name)
                        .navigationTitle(folder.name)
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    sandboxCard(folder: folder)
                }
            }
        }
    }

    private func sandboxCard(folder: SandboxFolder) -> some View {
        VStack(spacing: InspectorTheme.Spacing.sm) {
            Image(systemName: folder.icon)
                .font(.system(size: 22))
                .foregroundStyle(InspectorTheme.Colors.accent)

            Text(folder.name)
                .font(InspectorTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)

            Text(folderSize(for: folder))
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, InspectorTheme.Spacing.lg)
        .background(InspectorTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.lg))
    }

    private func folderSize(for folder: SandboxFolder) -> String {
        let size = FileSystemHelper.directorySize(at: folder.fullPath, depth: 0, maxDepth: 2)
        return FileSystemHelper.formattedSize(size)
    }

    // MARK: - Directory List

    private var directoryList: some View {
        VStack(spacing: 0) {
            if items.isEmpty {
                emptyState
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if item.isDirectory {
                        NavigationLink {
                            FileBrowserView(path: item.path, title: item.name)
                                .navigationTitle(item.name)
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            fileRow(item: item)
                        }
                    } else {
                        NavigationLink {
                            FilePreviewView(item: item)
                                .navigationTitle(item.name)
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            fileRow(item: item)
                        }
                    }

                    if index < items.count - 1 {
                        Divider()
                            .overlay(InspectorTheme.Colors.border)
                            .padding(.leading, 52)
                    }
                }
            }
        }
        .background(InspectorTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.lg))
    }

    private func fileRow(item: FileItem) -> some View {
        HStack(spacing: InspectorTheme.Spacing.md) {
            Image(systemName: item.icon)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(item.iconColor)
                .frame(width: 28, height: 28)
                .background(item.iconColor.opacity(0.12))
                .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))

            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                Text(item.name)
                    .font(InspectorTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: InspectorTheme.Spacing.sm) {
                    Text(FileSystemHelper.formattedSize(item.size))
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)

                    if let date = item.modifiedDate {
                        Text(FileSystemHelper.shortDate(date))
                            .font(InspectorTheme.Typography.detail)
                            .foregroundStyle(InspectorTheme.Colors.textTertiary)
                    }
                }
            }

            Spacer()

            if item.isDirectory {
                if let count = item.itemCount {
                    Text("\(count)")
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }

                Image(systemName: "chevron.right")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, InspectorTheme.Spacing.lg)
        .padding(.vertical, InspectorTheme.Spacing.md)
        .contentShape(.rect)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteItem(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                UIPasteboard.general.string = item.path
            } label: {
                Label("Copy Path", systemImage: "doc.on.doc")
            }
            .tint(InspectorTheme.Colors.accent)
        }
    }

    private var emptyState: some View {
        VStack(spacing: InspectorTheme.Spacing.sm) {
            Image(systemName: "folder")
                .font(.system(size: 28))
                .foregroundStyle(InspectorTheme.Colors.textTertiary)

            Text("Empty Directory")
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, InspectorTheme.Spacing.xxl)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(InspectorTheme.Colors.textTertiary)
            .padding(.bottom, InspectorTheme.Spacing.sm)
    }

    private func deleteItem(_ item: FileItem) {
        try? FileManager.default.removeItem(atPath: item.path)
        items.removeAll { $0.path == item.path }
    }
}

// MARK: - File Preview View

struct FilePreviewView: View {
    let item: FileItem

    @State private var fileContent: String?
    @State private var uiImage: UIImage?
    @State private var hexDump: String?
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.lg) {
                metadataSection

                if isLoading {
                    ProgressView()
                        .tint(InspectorTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, InspectorTheme.Spacing.xxl)
                } else {
                    contentSection
                }
            }
            .padding(.horizontal, InspectorTheme.Spacing.lg)
            .padding(.top, InspectorTheme.Spacing.sm)
            .padding(.bottom, InspectorTheme.Spacing.xl)
        }
        .inspectorBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CopyButtonView(valueToCopy: item.path)
            }
        }
        .task {
            loadContent()
        }
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        VStack(spacing: 0) {
            metadataRow(label: "Path", value: item.path, isFirst: true)
            metadataDivider
            metadataRow(label: "Size", value: FileSystemHelper.formattedSize(item.size))
            metadataDivider
            metadataRow(label: "Created", value: FileSystemHelper.formattedDate(item.createdDate))
            metadataDivider
            metadataRow(label: "Modified", value: FileSystemHelper.formattedDate(item.modifiedDate), isLast: true)
        }
        .background(InspectorTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.lg))
    }

    private func metadataRow(label: String, value: String, isFirst: Bool = false, isLast: Bool = false) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)
                .frame(width: 70, alignment: .leading)

            Spacer(minLength: InspectorTheme.Spacing.sm)

            Text(value)
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                .textSelection(.enabled)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, InspectorTheme.Spacing.lg)
        .padding(.vertical, InspectorTheme.Spacing.md)
    }

    private var metadataDivider: some View {
        Divider()
            .overlay(InspectorTheme.Colors.border)
            .padding(.leading, InspectorTheme.Spacing.lg)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentSection: some View {
        if let uiImage {
            imagePreview(uiImage)
        } else if let fileContent {
            CodeBlockView(text: fileContent, language: contentLanguage)
        } else if let hexDump {
            CodeBlockView(text: hexDump, language: .text)
        }
    }

    private func imagePreview(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
            sectionLabel("PREVIEW")

            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(.rect(cornerRadius: InspectorTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: InspectorTheme.Radius.md)
                        .stroke(InspectorTheme.Colors.border, lineWidth: 1)
                )

            HStack(spacing: InspectorTheme.Spacing.sm) {
                infoPill("\(Int(image.size.width))x\(Int(image.size.height))")
                infoPill("@\(Int(image.scale))x")
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(InspectorTheme.Colors.textTertiary)
    }

    private func infoPill(_ text: String) -> some View {
        Text(text)
            .font(InspectorTheme.Typography.detail)
            .foregroundStyle(InspectorTheme.Colors.textTertiary)
            .padding(.horizontal, InspectorTheme.Spacing.xs)
            .padding(.vertical, InspectorTheme.Spacing.xxs)
            .background(InspectorTheme.Colors.surfaceElevated)
            .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))
    }

    private var contentLanguage: ContentLanguage {
        let ext = (item.name as NSString).pathExtension.lowercased()
        switch ext {
        case "json": return .json
        case "plist", "xml", "html": return .xml
        default: return .text
        }
    }

    // MARK: - Loading

    private func loadContent() {
        // Images (by extension or magic bytes)
        if item.isImage {
            uiImage = UIImage(contentsOfFile: item.path)
            if uiImage == nil {
                hexDump = generateHexDump(at: item.path, maxBytes: 512)
            }
            isLoading = false
            return
        }

        // Binary plist (by extension or magic bytes) → convert to JSON
        if isPlistFile {
            fileContent = loadPlistAsText()
            if fileContent == nil {
                hexDump = generateHexDump(at: item.path, maxBytes: 512)
            }
            isLoading = false
            return
        }

        // SQLite auxiliary files (.db-shm, .db-wal, .db-journal) → just show metadata
        let ext = (item.name as NSString).pathExtension.lowercased()
        if ["db-shm", "db-wal", "db-journal"].contains(ext) {
            fileContent = nil
            hexDump = nil // Don't show hex for these - just metadata
            isLoading = false
            return
        }

        // Text-readable files
        if item.isTextReadable {
            fileContent = try? String(contentsOfFile: item.path, encoding: .utf8)
            if fileContent == nil {
                hexDump = generateHexDump(at: item.path, maxBytes: 512)
            }
            isLoading = false
            return
        }

        // Try reading as text
        if let text = try? String(contentsOfFile: item.path, encoding: .utf8),
           !text.isEmpty,
           text.utf8.count < 512_000 {
            fileContent = text
        } else {
            hexDump = generateHexDump(at: item.path, maxBytes: 512)
        }
        isLoading = false
    }

    private var isPlistFile: Bool {
        let ext = (item.name as NSString).pathExtension.lowercased()
        if ext == "plist" { return true }
        return item.isPlist
    }

    private func loadPlistAsText() -> String? {
        guard let data = FileManager.default.contents(atPath: item.path) else { return nil }

        if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) {
            let sanitized = sanitizeForJSON(plist)
            if JSONSerialization.isValidJSONObject(sanitized),
               let jsonData = try? JSONSerialization.data(withJSONObject: sanitized, options: [.prettyPrinted, .sortedKeys]),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            // Fallback: describe the plist
            return String(describing: plist)
        }

        return String(data: data, encoding: .utf8)
    }

    /// Converts plist types (Date, Data) to JSON-safe types (String).
    private func sanitizeForJSON(_ value: Any) -> Any {
        switch value {
        case let dict as [String: Any]:
            return dict.mapValues { sanitizeForJSON($0) }
        case let array as [Any]:
            return array.map { sanitizeForJSON($0) }
        case let date as Date:
            return date.formatted(.iso8601)
        case let data as Data:
            return "[Data: \(data.count) bytes]"
        default:
            return value
        }
    }

    private func generateHexDump(at path: String, maxBytes: Int) -> String? {
        guard let handle = FileHandle(forReadingAtPath: path) else { return nil }
        defer { handle.closeFile() }

        let data = handle.readData(ofLength: maxBytes)
        guard !data.isEmpty else { return nil }

        var lines: [String] = []
        let bytesPerLine = 16

        for offset in stride(from: 0, to: data.count, by: bytesPerLine) {
            let end = min(offset + bytesPerLine, data.count)
            let chunk = data[offset..<end]

            let addressStr = String(format: "%08X", offset)
            let hexPart = chunk.map { String(format: "%02X", $0) }.joined(separator: " ")
            let asciiPart = chunk.map { byte -> String in
                let scalar = Unicode.Scalar(byte)
                return (byte >= 0x20 && byte < 0x7F) ? String(scalar) : "."
            }.joined()

            let paddedHex = hexPart.padding(toLength: bytesPerLine * 3 - 1, withPad: " ", startingAt: 0)
            lines.append("\(addressStr)  \(paddedHex)  |\(asciiPart)|")
        }

        if data.count >= maxBytes {
            lines.append("")
            lines.append("... truncated at \(FileSystemHelper.formattedSize(Int64(maxBytes)))")
        }

        return lines.joined(separator: "\n")
    }
}
