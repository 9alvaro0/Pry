import SwiftUI

/// Renders text with search matches highlighted using AttributedString (preserves word wrap).
struct HighlightedText: View {
    let text: String
    let query: String
    let baseColor: Color

    var body: some View {
        if query.isEmpty || !text.lowercased().contains(query.lowercased()) {
            Text(text)
                .foregroundStyle(baseColor)
        } else {
            Text(buildAttributedString())
        }
    }

    private func buildAttributedString() -> AttributedString {
        var result = AttributedString(text)
        result.foregroundColor = baseColor

        let lower = text.lowercased()
        let queryLower = query.lowercased()
        var searchStart = lower.startIndex

        while let range = lower.range(of: queryLower, range: searchStart..<lower.endIndex) {
            guard let lowerBound = AttributedString.Index(range.lowerBound, within: result),
                  let upperBound = AttributedString.Index(range.upperBound, within: result) else {
                break
            }

            result[lowerBound..<upperBound].foregroundColor = UIColor(PryTheme.Colors.background)
            result[lowerBound..<upperBound].backgroundColor = UIColor(PryTheme.Colors.warning)

            searchStart = range.upperBound
        }

        return result
    }
}
