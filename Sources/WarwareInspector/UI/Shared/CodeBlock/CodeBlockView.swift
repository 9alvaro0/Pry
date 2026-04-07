import SwiftUI

struct CodeBlockView: View {
    let text: String
    var language: ContentLanguage = .text

    @State private var isExpanded = false

    private var detectedLanguage: ContentLanguage {
        ContentLanguage.detectLanguage(from: text, hint: language.rawValue)
    }

    private var shouldShowExpandButton: Bool {
        guard detectedLanguage.supportsExpansion else { return false }
        return text.components(separatedBy: .newlines).count > 8
    }

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
            if detectedLanguage != .json {
                CodeBlockHeaderView(
                    language: detectedLanguage.showsLanguageLabel ? detectedLanguage : nil,
                    text: text,
                    showExpandButton: shouldShowExpandButton,
                    isExpanded: $isExpanded
                )
            }

            switch detectedLanguage {
            case .json: JSONViewerView(jsonText: text)
            case .http: HTTPViewerView(httpText: text)
            default: PlainTextViewerView(text: text)
            }
        }
    }
}
