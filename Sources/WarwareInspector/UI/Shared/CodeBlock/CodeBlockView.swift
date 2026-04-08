import SwiftUI
import UIKit

/// Unified code block component with language detection, syntax highlighting, and copy support.
struct CodeBlockView: View {
    let text: String
    var language: ContentLanguage = .text

    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var isAllCollapsed = false

    private var resolvedLanguage: ContentLanguage {
        if language != .text && language != .plain {
            return language
        }
        return ContentLanguage.detect(from: text)
    }

    private var effectiveLanguage: ContentLanguage {
        let lang = resolvedLanguage
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

    private var isJSON: Bool { effectiveLanguage == .json && !isImage && !isFormEncoded(text) }
    private var isImage: Bool { text.hasPrefix("[IMAGE:") }

    private var displayLabel: String {
        if isImage { return "IMAGE" }
        if isFormEncoded(text) { return "FORM" }
        return effectiveLanguage.displayName.uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if isSearching && !isImage {
                searchBar
            }

            if isFormEncoded(text) {
                FormDataRenderer(text: text, searchQuery: searchQuery)
            } else if isImage {
                ImagePreviewView(encodedText: text)
            } else {
                switch effectiveLanguage {
                case .json:
                    JSONRenderer(
                        jsonText: text,
                        searchQuery: searchQuery,
                        collapseAll: isAllCollapsed
                    )
                default:
                    TextRenderer(text: text, language: effectiveLanguage, searchQuery: searchQuery)
                }
            }
        }
        .inspectorCodeBlock()
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
            HStack(spacing: InspectorTheme.Spacing.sm) {
                Text(displayLabel)
                    .font(InspectorTheme.Typography.detail)
                    .fontWeight(.semibold)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)

                if let size = sizeLabel {
                    Text(size)
                        .font(InspectorTheme.Typography.detail)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
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
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSearching.toggle()
                            if !isSearching { searchQuery = "" }
                        }
                    }
                }

                // Expand/Collapse toggle (JSON only)
                if isJSON {
                    headerButton(
                        icon: isAllCollapsed
                            ? "arrow.down.right.and.arrow.up.left"
                            : "arrow.up.left.and.arrow.down.right",
                        active: false
                    ) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isAllCollapsed.toggle()
                        }
                    }
                }

                // Copy
                CopyButtonView(valueToCopy: text)
                    .frame(height: 36)
            }
        }
        .padding(.bottom, InspectorTheme.Spacing.xs)
    }

    private func headerButton(icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(active ? InspectorTheme.Colors.accent : InspectorTheme.Colors.textSecondary)
                .frame(width: 36, height: 36)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: InspectorTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)

            TextField("Search...", text: $searchQuery)
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchQuery.isEmpty {
                Text("\(matchCount)")
                    .font(InspectorTheme.Typography.detail)
                    .fontWeight(.medium)
                    .foregroundStyle(matchCount > 0 ? InspectorTheme.Colors.accent : InspectorTheme.Colors.textTertiary)

                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, InspectorTheme.Spacing.sm)
        .padding(.vertical, InspectorTheme.Spacing.sm)
        .background(InspectorTheme.Colors.surfaceElevated)
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))
        .padding(.bottom, InspectorTheme.Spacing.sm)
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
    .inspectorBackground()
}

#Preview("JSON - Nested") {
    ScrollView {
        CodeBlockView(text: MockJSON.nested, language: .json)
            .padding()
    }
    .inspectorBackground()
}

#Preview("JSON - Invalid") {
    ScrollView {
        CodeBlockView(text: MockJSON.invalid, language: .json)
            .padding()
    }
    .inspectorBackground()
}

#Preview("Plain Text") {
    ScrollView {
        CodeBlockView(text: MockText.long)
            .padding()
    }
    .inspectorBackground()
}

#Preview("HTTP") {
    ScrollView {
        CodeBlockView(text: MockHTTP.postRequest, language: .http)
            .padding()
    }
    .inspectorBackground()
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
    .inspectorBackground()
}
#endif
