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
        static let border          = Color.white.opacity(Opacity.border)
        static let overlay         = Color.black.opacity(Opacity.overlay)

        // Text
        static let textPrimary   = Color.white
        static let textSecondary = Color.white.opacity(Opacity.textSecondary)
        static let textTertiary  = Color.white.opacity(Opacity.textTertiary)

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
        static let accentMild = Color(hex: "#41A1F5").opacity(Opacity.badge)

        // FAB
        static let fab           = Color.red
        static let fabForeground = Color.white

        // Badges
        static func statusBackground(_ code: Int) -> Color {
            switch code {
            case 200..<300: return success.opacity(Opacity.badge)
            case 300..<400: return warning.opacity(Opacity.badge)
            case 400..<600: return error.opacity(Opacity.badge)
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
        static let heading    = Font.headline
        static let subheading = Font.subheadline.weight(.medium)
        static let body       = Font.caption
        static let detail     = Font.caption2
        static let code       = Font.system(.caption, design: .monospaced)
        static let codeSmall  = Font.system(.caption2, design: .monospaced)

        // Explicit size fonts (for cases where semantic fonts don't fit)
        static let sectionLabel = Font.system(size: FontSize.sectionLabel, weight: .semibold)
        static let badgeText    = Font.system(size: FontSize.badge, weight: .bold)
        static let smallIcon    = Font.system(size: FontSize.smallIcon)
        static let largeMetric  = Font.system(size: FontSize.largeMetric, weight: .medium, design: .monospaced)
        static let chartLabel   = Font.system(size: FontSize.chartLabel)
    }

    // MARK: - Font Sizes (raw values for Typography)

    enum FontSize {
        static let chartLabel:   CGFloat = 8
        static let badge:        CGFloat = 9
        static let smallIcon:    CGFloat = 10
        static let sectionLabel: CGFloat = 11
        static let largeMetric:  CGFloat = 18
        static let emptyState:   CGFloat = 28
    }

    // MARK: - Spacing (4pt grid)

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs:  CGFloat = 4
        static let pip: CGFloat = 6
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
        static let statusDot:     CGFloat = 8
        static let toggleIcon:    CGFloat = 16
        static let diffLabelSmall: CGFloat = 18
        static let iconSmall:     CGFloat = 20
        static let diffLabel:     CGFloat = 22
        static let formKeyWidth:  CGFloat = 24
        static let iconMedium:    CGFloat = 28
        static let iconLarge:     CGFloat = 36
        static let methodColumn:  CGFloat = 52
        static let fab:           CGFloat = 56
        static let metadataLabel: CGFloat = 70
        static let rowMinHeight:  CGFloat = 72
        static let chartHeight:   CGFloat = 100
        static let editorMinHeight: CGFloat = 200
        static let imageMaxHeight: CGFloat = 300
    }

    // MARK: - Opacity

    enum Opacity {
        static let subtle:        Double = 0.05
        static let faint:         Double = 0.08
        static let border:        Double = 0.1
        static let tint:          Double = 0.12
        static let badge:         Double = 0.15
        static let medium:        Double = 0.2
        static let moderate:      Double = 0.3
        static let textTertiary:  Double = 0.45
        static let overlay:       Double = 0.5
        static let textSecondary: Double = 0.7
    }

    // MARK: - Animation

    enum Animation {
        static let quick:    Double = 0.15
        static let standard: Double = 0.2
        static let toastDismiss: Duration = .seconds(1.5)
        static let toastLong:   Duration = .seconds(3)
        static let feedbackDelay: Duration = .seconds(1)
        static let replayDismiss: Duration = .seconds(2)
    }

    // MARK: - Text

    enum Text {
        static let tracking: CGFloat = 0.5
        static let truncateLength: Int = 30
        static let cellTruncateLength: Int = 200
    }

    // MARK: - Shadow

    enum Shadow {
        static let radius:  CGFloat = 6
        static let offsetX: CGFloat = 0
        static let offsetY: CGFloat = 3
        static let opacity: Double  = 0.2
    }
}
