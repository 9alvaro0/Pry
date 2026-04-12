import SwiftUI
import UIKit

/// Unified code block component with language detection, syntax highlighting, and copy support.
@_spi(PryPro) public struct CodeBlockView: View {
    @_spi(PryPro) public let text: String
    @_spi(PryPro) public var language: ContentLanguage = .text

    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var isAllCollapsed = false
    @State private var forceRaw = false

    private let resolvedEffectiveLanguage: ContentLanguage

    @_spi(PryPro) public init(text: String, language: ContentLanguage = .text) {
        self.text = text
        self.language = language
        self.resolvedEffectiveLanguage = Self.resolveLanguage(text: text, language: language)
    }

    private static func resolveLanguage(text: String, language: ContentLanguage) -> ContentLanguage {
        let lang: ContentLanguage
        if language != .text && language != .plain {
            lang = language
        } else {
            lang = ContentLanguage.detect(from: text)
        }
        if lang == .json {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if let data = trimmed.data(using: .utf8),
               (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)) != nil {
                return .json
            }
            return .text
        }
        return lang
    }

    private var effectiveLanguage: ContentLanguage { resolvedEffectiveLanguage }

    private var isJSON: Bool { effectiveLanguage == .json && !isImage && !isFormEncoded(text) }
    private var isImage: Bool { text.hasPrefix("[IMAGE:") }

    private var displayLabel: String {
        if isImage { return "IMAGE" }
        if isFormEncoded(text) { return "FORM" }
        return effectiveLanguage.displayName.uppercased()
    }

    @_spi(PryPro) public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if isSearching && !isImage {
                searchBar
            }

            if isFormEncoded(text) {
                FormDataRenderer(text: text, searchQuery: searchQuery)
            } else if isImage {
                ImagePreviewView(encodedText: text)
            } else if isJSON && !forceRaw {
                JSONRenderer(
                    jsonText: text,
                    searchQuery: searchQuery,
                    collapseAll: isAllCollapsed
                )
            } else {
                TextRenderer(text: text, language: effectiveLanguage, searchQuery: searchQuery)
            }
        }
        .pryCodeBlock()
    }

    private func isFormEncoded(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.hasPrefix("{"),
              !trimmed.hasPrefix("["),
              !trimmed.hasPrefix("<"),
              trimmed.contains("=") else { return false }
        // Basic check: has key=value pattern
        return trimmed.contains("&") || trimmed.range(of: "^[^=]+=", options: .regularExpression) != nil
    }

    // MARK: - Header (single line: label + icon buttons)

    private var sizeLabel: String? {
        let bytes = text.utf8.count
        guard bytes > 0 else { return nil }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private var header: some View {
        HStack {
            HStack(spacing: PryTheme.Spacing.sm) {
                if isJSON {
                    // JSON/Raw toggle tabs
                    Button {
                        forceRaw = false
                    } label: {
                        Text("JSON")
                            .font(PryTheme.Typography.detail)
                            .fontWeight(.semibold)
                            .foregroundStyle(!forceRaw ? PryTheme.Colors.accent : PryTheme.Colors.textTertiary)
                    }

                    Button {
                        forceRaw = true
                    } label: {
                        Text("Raw")
                            .font(PryTheme.Typography.detail)
                            .fontWeight(.semibold)
                            .foregroundStyle(forceRaw ? PryTheme.Colors.accent : PryTheme.Colors.textTertiary)
                    }
                } else {
                    Text(displayLabel)
                        .font(PryTheme.Typography.detail)
                        .fontWeight(.semibold)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }

                if let size = sizeLabel {
                    Text(size)
                        .font(PryTheme.Typography.detail)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }
            }

            Spacer()

            HStack(spacing: 0) {
                if !isImage {
                    // Search toggle
                    headerButton(
                        icon: "magnifyingglass",
                        active: isSearching
                    ) {
                        withAnimation(.easeInOut(duration: PryTheme.Animation.standard)) {
                            isSearching.toggle()
                            if !isSearching { searchQuery = "" }
                        }
                    }
                }

                // Expand/Collapse toggle (JSON only, not in raw mode)
                if isJSON && !forceRaw {
                    headerButton(
                        icon: isAllCollapsed
                            ? "arrow.down.right.and.arrow.up.left"
                            : "arrow.up.left.and.arrow.down.right",
                        active: false
                    ) {
                        withAnimation(.easeOut(duration: PryTheme.Animation.standard)) {
                            isAllCollapsed.toggle()
                        }
                    }
                }

                // Copy
                CopyButtonView(valueToCopy: text)
                    .frame(height: PryTheme.Size.iconLarge)
            }
        }
        .padding(.bottom, PryTheme.Spacing.xs)
    }

    private func headerButton(icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(PryTheme.Typography.body)
                .foregroundStyle(active ? PryTheme.Colors.accent : PryTheme.Colors.textSecondary)
                .frame(width: PryTheme.Size.iconLarge, height: PryTheme.Size.iconLarge)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: PryTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)

            TextField("Search...", text: $searchQuery)
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchQuery.isEmpty {
                Text("\(matchCount)")
                    .font(PryTheme.Typography.detail)
                    .fontWeight(.medium)
                    .foregroundStyle(matchCount > 0 ? PryTheme.Colors.accent : PryTheme.Colors.textTertiary)

                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, PryTheme.Spacing.sm)
        .padding(.vertical, PryTheme.Spacing.sm)
        .background(PryTheme.Colors.surfaceElevated)
        .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))
        .padding(.bottom, PryTheme.Spacing.sm)
    }

    private var matchCount: Int {
        guard !searchQuery.isEmpty else { return 0 }
        let query = searchQuery.lowercased()
        let content = text.lowercased()
        var count = 0
        var range = content.startIndex..<content.endIndex
        while let found = content.range(of: query, range: range) {
            count += 1
            range = found.upperBound..<content.endIndex
        }
        return count
    }
}

// MARK: - Previews

#if DEBUG
#Preview("JSON - Simple") {
    ScrollView {
        CodeBlockView(text: MockJSON.simple, language: .json)
            .padding()
    }
    .pryBackground()
}

#Preview("JSON - Nested") {
    ScrollView {
        CodeBlockView(text: MockJSON.nested, language: .json)
            .padding()
    }
    .pryBackground()
}

#Preview("JSON - Invalid") {
    ScrollView {
        CodeBlockView(text: MockJSON.invalid, language: .json)
            .padding()
    }
    .pryBackground()
}

#Preview("Plain Text") {
    ScrollView {
        CodeBlockView(text: MockText.long)
            .padding()
    }
    .pryBackground()
}

#Preview("HTTP") {
    ScrollView {
        CodeBlockView(text: MockHTTP.postRequest, language: .http)
            .padding()
    }
    .pryBackground()
}

#Preview("Auto-Detection") {
    ScrollView {
        VStack(spacing: 16) {
            CodeBlockView(text: MockJSON.simple)
            CodeBlockView(text: MockHTTP.getMinimal)
            CodeBlockView(text: MockText.short)
        }
        .padding()
    }
    .pryBackground()
}
#endif
