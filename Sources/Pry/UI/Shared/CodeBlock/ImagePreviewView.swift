import SwiftUI
import UIKit

/// Renders a preview of image data encoded as [IMAGE:size:base64].
package struct ImagePreviewView: View {
    package let encodedText: String

    private var imageData: (size: Int, image: UIImage?)? {
        // Parse "[IMAGE:size:base64data]"
        let stripped = String(encodedText.dropFirst(7).dropLast(1))
        guard let colonIndex = stripped.firstIndex(of: ":") else { return nil }
        let sizeStr = String(stripped[stripped.startIndex..<colonIndex])
        let base64 = String(stripped[stripped.index(after: colonIndex)...])
        guard let size = Int(sizeStr),
              let data = Data(base64Encoded: base64) else { return nil }
        return (size, UIImage(data: data))
    }

    package var body: some View {
        if let parsed = imageData, let uiImage = parsed.image {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: PryTheme.Size.imageMaxHeight)
                .clipShape(.rect(cornerRadius: PryTheme.Radius.md))
        } else {
            Text("[Image data - unable to preview]")
                .font(PryTheme.Typography.code)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Image Preview") {
    ScrollView {
        // Generate a small red 50x50 PNG programmatically
        let image = {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 60))
            return renderer.pngData { ctx in
                UIColor.systemBlue.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 60))
                let attrs: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.boldSystemFont(ofSize: 14)
                ]
                "Preview".draw(at: CGPoint(x: 20, y: 20), withAttributes: attrs)
            }
        }()
        let base64 = image.base64EncodedString()
        let encoded = "[IMAGE:\(image.count):\(base64)]"

        CodeBlockView(text: encoded)
            .padding()
    }
    .pryBackground()
}

#Preview("Image - Invalid Data") {
    ScrollView {
        ImagePreviewView(encodedText: "[IMAGE:999:notvalidbase64]")
            .padding()
    }
    .pryBackground()
}
#endif
