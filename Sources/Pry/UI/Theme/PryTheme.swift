import SwiftUI

/// Single source of truth for all design tokens in Pry.
///
/// Dark developer aesthetic inspired by Xcode and Charles Proxy.
package enum PryTheme {

    // MARK: - Colors

    package enum Colors {
        // Backgrounds
        package static let background      = Color(hex: "#1C1C1E")
        package static let surface         = Color(hex: "#2C2C2E")
        package static let surfaceElevated = Color(hex: "#3A3A3C")
        package static let border          = Color.white.opacity(Opacity.border)
        package static let overlay         = Color.black.opacity(Opacity.overlay)

        // Text
        package static let textPrimary   = Color.white
        package static let textSecondary = Color.white.opacity(Opacity.textSecondary)
        package static let textTertiary  = Color.white.opacity(Opacity.textTertiary)

        // Status
        package static let success = Color.green
        package static let error   = Color.red
        package static let warning = Color.orange
        package static let pending = Color.yellow
        package static let info    = Color(hex: "#41A1F5")

        // Syntax highlighting (Xcode-inspired)
        package static let syntaxKey    = Color(hex: "#FF7AB2")
        package static let syntaxString = Color(hex: "#FC6A5D")
        package static let syntaxNumber = Color(hex: "#D0BF69")
        package static let syntaxBool   = Color(hex: "#B281EB")
        package static let syntaxNull   = Color.gray

        // HTTP Methods
        package static let methodGet    = Color(hex: "#41A1F5")
        package static let methodPost   = Color.green
        package static let methodPut    = Color.orange
        package static let methodDelete = Color.red
        package static let methodPatch  = Color(hex: "#B281EB")

        // Feature accents
        package static let network   = Color(hex: "#41A1F5")
        package static let console   = Color.green
        package static let deeplinks = Color.indigo

        // Interactive
        package static let accent     = Color(hex: "#41A1F5")
        package static let accentMild = Color(hex: "#41A1F5").opacity(Opacity.badge)

        // FAB
        package static let fab           = Color.red
        package static let fabForeground = Color.white

        // Badges
        package static func statusBackground(_ code: Int) -> Color {
            switch code {
            case 200..<300: return success.opacity(Opacity.badge)
            case 300..<400: return warning.opacity(Opacity.badge)
            case 400..<600: return error.opacity(Opacity.badge)
            default: return surface
            }
        }

        package static func statusForeground(_ code: Int) -> Color {
            switch code {
            case 200..<300: return success
            case 300..<400: return warning
            case 400..<600: return error
            default: return textSecondary
            }
        }

        package static func methodColor(_ method: String) -> Color {
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

    package enum Typography {
        package static let heading    = Font.headline
        package static let subheading = Font.subheadline.weight(.medium)
        package static let body       = Font.caption
        package static let detail     = Font.caption2
        package static let code       = Font.system(.caption, design: .monospaced)
        package static let codeSmall  = Font.system(.caption2, design: .monospaced)

        // Explicit size fonts (for cases where semantic fonts don't fit)
        package static let sectionLabel = Font.system(size: FontSize.sectionLabel, weight: .semibold)
        package static let badgeText    = Font.system(size: FontSize.badge, weight: .bold)
        package static let smallIcon    = Font.system(size: FontSize.smallIcon)
        package static let largeMetric  = Font.system(size: FontSize.largeMetric, weight: .medium, design: .monospaced)
        package static let chartLabel   = Font.system(size: FontSize.chartLabel)
    }

    // MARK: - Font Sizes (raw values for Typography)

    package enum FontSize {
        package static let chartLabel:   CGFloat = 8
        package static let badge:        CGFloat = 9
        package static let smallIcon:    CGFloat = 10
        package static let sectionLabel: CGFloat = 11
        package static let largeMetric:  CGFloat = 18
        package static let emptyState:   CGFloat = 28
    }

    // MARK: - Spacing (4pt grid)

    package enum Spacing {
        package static let xxs: CGFloat = 2
        package static let xs:  CGFloat = 4
        package static let pip: CGFloat = 6
        package static let sm:  CGFloat = 8
        package static let md:  CGFloat = 12
        package static let lg:  CGFloat = 16
        package static let xl:  CGFloat = 20
        package static let xxl: CGFloat = 24
    }

    // MARK: - Radius

    package enum Radius {
        package static let sm:  CGFloat = 4
        package static let md:  CGFloat = 8
        package static let lg:  CGFloat = 12
    }

    // MARK: - Sizes

    package enum Size {
        package static let statusDot:     CGFloat = 8
        package static let toggleIcon:    CGFloat = 16
        package static let diffLabelSmall: CGFloat = 18
        package static let iconSmall:     CGFloat = 20
        package static let diffLabel:     CGFloat = 22
        package static let formKeyWidth:  CGFloat = 24
        package static let iconMedium:    CGFloat = 28
        package static let iconLarge:     CGFloat = 36
        package static let methodColumn:  CGFloat = 52
        package static let fab:           CGFloat = 56
        package static let metadataLabel: CGFloat = 70
        package static let rowMinHeight:  CGFloat = 72
        package static let chartHeight:   CGFloat = 100
        package static let editorMinHeight: CGFloat = 200
        package static let imageMaxHeight: CGFloat = 300
    }

    // MARK: - Opacity

    package enum Opacity {
        package static let subtle:        Double = 0.05
        package static let faint:         Double = 0.08
        package static let border:        Double = 0.1
        package static let tint:          Double = 0.12
        package static let badge:         Double = 0.15
        package static let medium:        Double = 0.2
        package static let moderate:      Double = 0.3
        package static let textTertiary:  Double = 0.45
        package static let overlay:       Double = 0.5
        package static let textSecondary: Double = 0.7
    }

    // MARK: - Animation

    package enum Animation {
        package static let quick:    Double = 0.15
        package static let standard: Double = 0.2
        package static let toastDismiss: Duration = .seconds(1.5)
        package static let toastLong:   Duration = .seconds(3)
        package static let feedbackDelay: Duration = .seconds(1)
        package static let replayDismiss: Duration = .seconds(2)
    }

    // MARK: - Text

    package enum Text {
        package static let tracking: CGFloat = 0.5
        package static let truncateLength: Int = 30
        package static let cellTruncateLength: Int = 200
    }

    // MARK: - Shadow

    package enum Shadow {
        package static let radius:  CGFloat = 6
        package static let offsetX: CGFloat = 0
        package static let offsetY: CGFloat = 3
        package static let opacity: Double  = 0.2
    }
}
