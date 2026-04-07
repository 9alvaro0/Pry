import SwiftUI

/// Single source of truth for all design tokens in WarwareInspector.
///
/// Dark developer aesthetic inspired by Xcode and Charles Proxy.
enum InspectorTheme {

    // MARK: - Colors

    enum Colors {
        // Backgrounds
        static let background      = Color(hex: "#1C1C1E")
        static let surface         = Color(hex: "#2C2C2E")
        static let surfaceElevated = Color(hex: "#3A3A3C")
        static let border          = Color.white.opacity(0.1)
        static let overlay         = Color.black.opacity(0.5)

        // Text
        static let textPrimary   = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary  = Color.white.opacity(0.45)

        // Status
        static let success = Color.green
        static let error   = Color.red
        static let warning = Color.orange
        static let pending = Color.yellow
        static let info    = Color(hex: "#41A1F5")

        // Syntax highlighting (Xcode-inspired)
        static let syntaxKey    = Color(hex: "#FF7AB2")
        static let syntaxString = Color(hex: "#FC6A5D")
        static let syntaxNumber = Color(hex: "#D0BF69")
        static let syntaxBool   = Color(hex: "#B281EB")
        static let syntaxNull   = Color.gray

        // HTTP Methods
        static let methodGet    = Color(hex: "#41A1F5")
        static let methodPost   = Color.green
        static let methodPut    = Color.orange
        static let methodDelete = Color.red
        static let methodPatch  = Color(hex: "#B281EB")

        // Feature accents
        static let network   = Color(hex: "#41A1F5")
        static let console   = Color.green
        static let deeplinks = Color.indigo

        // Interactive
        static let accent     = Color(hex: "#41A1F5")
        static let accentMild = Color(hex: "#41A1F5").opacity(0.15)

        // FAB
        static let fab           = Color.red
        static let fabForeground = Color.white

        // Badges
        static func statusBackground(_ code: Int) -> Color {
            switch code {
            case 200..<300: return success.opacity(0.15)
            case 300..<400: return warning.opacity(0.15)
            case 400..<600: return error.opacity(0.15)
            default: return surface
            }
        }

        static func statusForeground(_ code: Int) -> Color {
            switch code {
            case 200..<300: return success
            case 300..<400: return warning
            case 400..<600: return error
            default: return textSecondary
            }
        }

        static func methodColor(_ method: String) -> Color {
            switch method.uppercased() {
            case "GET":    return methodGet
            case "POST":   return methodPost
            case "PUT":    return methodPut
            case "DELETE": return methodDelete
            case "PATCH":  return methodPatch
            default:       return textSecondary
            }
        }
    }

    // MARK: - Typography

    enum Typography {
        static let heading   = Font.headline
        static let subheading = Font.subheadline.weight(.medium)
        static let body      = Font.caption
        static let detail    = Font.caption2
        static let code      = Font.system(.caption, design: .monospaced)
        static let codeSmall = Font.system(.caption2, design: .monospaced)
    }

    // MARK: - Spacing (4pt grid)

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 12
        static let lg:  CGFloat = 16
        static let xl:  CGFloat = 20
        static let xxl: CGFloat = 24
    }

    // MARK: - Radius

    enum Radius {
        static let sm:  CGFloat = 4
        static let md:  CGFloat = 8
        static let lg:  CGFloat = 12
    }

    // MARK: - Sizes

    enum Size {
        static let statusDot:  CGFloat = 8
        static let iconSmall:  CGFloat = 16
        static let iconMedium: CGFloat = 20
        static let fab:        CGFloat = 56
        static let exportDialog: CGFloat = 260
    }
}
