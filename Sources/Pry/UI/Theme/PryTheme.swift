import SwiftUI

/// Single source of truth for all design tokens in Pry.
///
/// Dark developer aesthetic inspired by Xcode and Charles Proxy.
@_spi(PryPro) public enum PryTheme {

    // MARK: - Colors

    @_spi(PryPro) public enum Colors {
        // Backgrounds
        @_spi(PryPro) public static let background      = Color.adaptive(light: "#F5F5F7", dark: "#0D1017")
        @_spi(PryPro) public static let surface         = Color.adaptive(light: "#FFFFFF", dark: "#141820")
        @_spi(PryPro) public static let surfaceElevated = Color.adaptive(light: "#F0F0F2", dark: "#1C2230")
        @_spi(PryPro) public static let border          = Color.adaptive(light: "#E0E0E4", dark: "#1E2530")
        @_spi(PryPro) public static let overlay         = Color.black.opacity(Opacity.overlay)

        // Text
        @_spi(PryPro) public static let textPrimary   = Color.adaptive(light: "#1C1C1E", dark: "#E7ECF0")
        @_spi(PryPro) public static let textSecondary = Color.adaptive(light: "#6C6C70", dark: "#9099A6")
        @_spi(PryPro) public static let textTertiary  = Color.adaptive(light: "#AEAEB2", dark: "#5A6370")

        // Status
        @_spi(PryPro) public static let success = Color(hex: "#22C55E")
        @_spi(PryPro) public static let error   = Color(hex: "#EF4444")
        @_spi(PryPro) public static let warning = Color(hex: "#F59E0B")
        @_spi(PryPro) public static let pending = Color(hex: "#EAB308")
        @_spi(PryPro) public static let info    = Color(hex: "#3B82F6")

        // Syntax highlighting (Xcode-inspired, adaptive)
        @_spi(PryPro) public static let syntaxKey    = Color.adaptive(light: "#9B2393", dark: "#FF7AB2")
        @_spi(PryPro) public static let syntaxString = Color.adaptive(light: "#C41A16", dark: "#FC6A5D")
        @_spi(PryPro) public static let syntaxNumber = Color.adaptive(light: "#1C00CF", dark: "#D0BF69")
        @_spi(PryPro) public static let syntaxBool   = Color.adaptive(light: "#6C36A9", dark: "#B281EB")
        @_spi(PryPro) public static let syntaxNull   = Color.gray

        // HTTP Methods
        @_spi(PryPro) public static let methodGet    = Color(hex: "#3B82F6")
        @_spi(PryPro) public static let methodPost   = Color(hex: "#22C55E")
        @_spi(PryPro) public static let methodPut    = Color(hex: "#F59E0B")
        @_spi(PryPro) public static let methodDelete = Color(hex: "#EF4444")
        @_spi(PryPro) public static let methodPatch  = Color(hex: "#8B5CF6")

        // Feature accents
        @_spi(PryPro) public static let network      = Color(hex: "#3B82F6")
        @_spi(PryPro) public static let console       = Color(hex: "#22C55E")
        @_spi(PryPro) public static let deeplinks     = Color(hex: "#8B5CF6")
        @_spi(PryPro) public static let push          = Color(hex: "#F59E0B")
        @_spi(PryPro) public static let cookies       = Color(hex: "#C9A84C")
        @_spi(PryPro) public static let userDefaults  = Color(hex: "#22C55E")
        @_spi(PryPro) public static let device        = Color(hex: "#EF4444")
        @_spi(PryPro) public static let permissions   = Color(hex: "#3B82F6")

        // Interactive
        @_spi(PryPro) public static let accent     = Color(hex: "#FF4B5C")
        @_spi(PryPro) public static let accentMild = Color(hex: "#FF4B5C").opacity(Opacity.badge)

        // FAB
        @_spi(PryPro) public static let fab           = Color(hex: "#FF4B5C")
        @_spi(PryPro) public static let fabForeground = Color.white

        // Badges
        @_spi(PryPro) public static func statusBackground(_ code: Int) -> Color {
            switch code {
            case 200..<300: return success.opacity(Opacity.badge)
            case 300..<400: return warning.opacity(Opacity.badge)
            case 400..<600: return error.opacity(Opacity.badge)
            default: return surface
            }
        }

        @_spi(PryPro) public static func statusForeground(_ code: Int) -> Color {
            switch code {
            case 200..<300: return success
            case 300..<400: return warning
            case 400..<600: return error
            default: return textSecondary
            }
        }

        @_spi(PryPro) public static func methodColor(_ method: String) -> Color {
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

    @_spi(PryPro) public enum Typography {
        @_spi(PryPro) public static let heading    = Font.headline
        @_spi(PryPro) public static let subheading = Font.subheadline.weight(.medium)
        @_spi(PryPro) public static let body       = Font.caption
        @_spi(PryPro) public static let detail     = Font.caption2
        @_spi(PryPro) public static let code       = Font.system(.caption, design: .monospaced)
        @_spi(PryPro) public static let codeSmall  = Font.system(.caption2, design: .monospaced)

        // Explicit size fonts (for cases where semantic fonts don't fit)
        @_spi(PryPro) public static let sectionLabel = Font.system(size: FontSize.sectionLabel, weight: .semibold)
        @_spi(PryPro) public static let badgeText    = Font.system(size: FontSize.badge, weight: .bold)
        @_spi(PryPro) public static let smallIcon    = Font.system(size: FontSize.smallIcon)
        @_spi(PryPro) public static let largeMetric  = Font.system(size: FontSize.largeMetric, weight: .medium, design: .monospaced)
        @_spi(PryPro) public static let chartLabel   = Font.system(size: FontSize.chartLabel)
    }

    // MARK: - Font Sizes (raw values for Typography)

    @_spi(PryPro) public enum FontSize {
        @_spi(PryPro) public static let chartLabel:   CGFloat = 8
        @_spi(PryPro) public static let badge:        CGFloat = 9
        @_spi(PryPro) public static let smallIcon:    CGFloat = 10
        @_spi(PryPro) public static let sectionLabel: CGFloat = 11
        @_spi(PryPro) public static let largeMetric:  CGFloat = 18
        @_spi(PryPro) public static let emptyState:   CGFloat = 28
    }

    // MARK: - Spacing (4pt grid)

    @_spi(PryPro) public enum Spacing {
        @_spi(PryPro) public static let xxs: CGFloat = 2
        @_spi(PryPro) public static let xs:  CGFloat = 4
        @_spi(PryPro) public static let pip: CGFloat = 6
        @_spi(PryPro) public static let sm:  CGFloat = 8
        @_spi(PryPro) public static let md:  CGFloat = 12
        @_spi(PryPro) public static let lg:  CGFloat = 16
        @_spi(PryPro) public static let xl:  CGFloat = 20
        @_spi(PryPro) public static let xxl: CGFloat = 24
    }

    // MARK: - Radius

    @_spi(PryPro) public enum Radius {
        @_spi(PryPro) public static let sm:  CGFloat = 4
        @_spi(PryPro) public static let md:  CGFloat = 8
        @_spi(PryPro) public static let lg:  CGFloat = 12
    }

    // MARK: - Sizes

    @_spi(PryPro) public enum Size {
        @_spi(PryPro) public static let statusDot:     CGFloat = 8
        @_spi(PryPro) public static let toggleIcon:    CGFloat = 16
        @_spi(PryPro) public static let diffLabelSmall: CGFloat = 18
        @_spi(PryPro) public static let iconSmall:     CGFloat = 20
        @_spi(PryPro) public static let diffLabel:     CGFloat = 22
        @_spi(PryPro) public static let formKeyWidth:  CGFloat = 24
        @_spi(PryPro) public static let iconMedium:    CGFloat = 28
        @_spi(PryPro) public static let iconLarge:     CGFloat = 36
        @_spi(PryPro) public static let methodColumn:  CGFloat = 52
        @_spi(PryPro) public static let fab:           CGFloat = 56
        @_spi(PryPro) public static let metadataLabel: CGFloat = 70
        @_spi(PryPro) public static let rowMinHeight:  CGFloat = 72
        @_spi(PryPro) public static let chartHeight:   CGFloat = 100
        @_spi(PryPro) public static let editorMinHeight: CGFloat = 200
        @_spi(PryPro) public static let imageMaxHeight: CGFloat = 300
    }

    // MARK: - Opacity

    @_spi(PryPro) public enum Opacity {
        @_spi(PryPro) public static let subtle:        Double = 0.05
        @_spi(PryPro) public static let faint:         Double = 0.08
        @_spi(PryPro) public static let border:        Double = 0.1
        @_spi(PryPro) public static let tint:          Double = 0.12
        @_spi(PryPro) public static let badge:         Double = 0.15
        @_spi(PryPro) public static let medium:        Double = 0.2
        @_spi(PryPro) public static let moderate:      Double = 0.3
        @_spi(PryPro) public static let textTertiary:  Double = 0.45
        @_spi(PryPro) public static let overlay:       Double = 0.5
        @_spi(PryPro) public static let textSecondary: Double = 0.7
    }

    // MARK: - Animation

    @_spi(PryPro) public enum Animation {
        @_spi(PryPro) public static let quick:    Double = 0.15
        @_spi(PryPro) public static let standard: Double = 0.2
        @_spi(PryPro) public static let toastDismiss: Duration = .seconds(1.5)
        @_spi(PryPro) public static let toastLong:   Duration = .seconds(3)
        @_spi(PryPro) public static let feedbackDelay: Duration = .seconds(1)
        @_spi(PryPro) public static let replayDismiss: Duration = .seconds(2)
    }

    // MARK: - Text

    @_spi(PryPro) public enum Text {
        @_spi(PryPro) public static let tracking: CGFloat = 0.5
        @_spi(PryPro) public static let truncateLength: Int = 30
        @_spi(PryPro) public static let cellTruncateLength: Int = 200
    }

    // MARK: - Shadow

    @_spi(PryPro) public enum Shadow {
        @_spi(PryPro) public static let radius:  CGFloat = 6
        @_spi(PryPro) public static let offsetX: CGFloat = 0
        @_spi(PryPro) public static let offsetY: CGFloat = 3
        @_spi(PryPro) public static let opacity: Double  = 0.2
    }
}
