import SwiftUI

/// Central design tokens used across the app (colors, spacing, radii, fonts, gradients).
/// Lean and readable, geared for the new calm/modern moodboard (blue/violet + glass look).
struct AppTheme {
    /// Back-compat: allow `AppTheme.Color` (alias to SwiftUI.Color)
    typealias Color = SwiftUI.Color
    // MARK: - Colors
    static let backgroundPrimary   = Color(hex: "#070A15")
    static let backgroundSecondary = Color(hex: "#0B1225")
    static let background = backgroundPrimary
    static let surfaceElevated = Color.white.opacity(0.06)
    /// Base surface color (alias to elevated for now; keeps API simple in views)
    static let surface = surfaceElevated
    static let surfaceGlassDarkTop = Color.white.opacity(0.10)
    static let surfaceGlassDarkBottom = Color.white.opacity(0.02)
    static let iconPrimary = Color.white
    static let iconSecondary = Color.white.opacity(0.7)
    static let separator = Color.white.opacity(0.08)
    static let cardBackground = surfaceElevated
    static let accent = Color(hex: "#4B3F9E")
    static let accentDeep = Color(hex: "#3A2D7A")
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "#4B3F9E"), Color(hex: "#3A2D7A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static var pillGradient: LinearGradient { capsuleGradient }
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    /// Alias for older call-sites
    public static let secondary = textSecondary
    static let secondaryText = textSecondary
    static let highlight = Color(hex: "#C084FC")

    // Legacy tokens used in older views (kept for back-compat)
    static let danger = Color(hex: "#EF4444")
    static let shadowCard = Color.black.opacity(0.25)

    /// Dynamic plain card background color (compat with old call-sites calling a function)
    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? surfaceElevated : Color.black.opacity(0.05)
    }

    /// Subtle card stroke for glass look
    static func cardStroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.08)
    }

    static func tabBarBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.28) : Color.white.opacity(0.85)
    }
    static func listBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? backgroundSecondary : Color.white
    }

    // MARK: - Color namespace (backwards-compat for AppTheme.Colors.*)
    struct Colors {
        // Backgrounds & surfaces
        static let backgroundPrimary   = AppTheme.backgroundPrimary
        static let backgroundSecondary = AppTheme.backgroundSecondary
        static let background          = AppTheme.background
        static let surfaceElevated     = AppTheme.surfaceElevated
        static let surface          = AppTheme.surface
        static let surfaceGlassDarkTop = AppTheme.surfaceGlassDarkTop
        static let surfaceGlassDarkBottom = AppTheme.surfaceGlassDarkBottom
        static let cardBackground      = AppTheme.cardBackground
        static let separator           = AppTheme.separator
        static let shadowCard          = AppTheme.shadowCard

        // Content & icons
        static let iconPrimary   = AppTheme.iconPrimary
        static let iconSecondary = AppTheme.iconSecondary

        // Text
        static let textPrimary   = AppTheme.textPrimary
        static let textSecondary = AppTheme.textSecondary
        static let textTertiary = AppTheme.textTertiary
        static let secondary     = AppTheme.secondary
        static let secondaryText = AppTheme.textSecondary
        static let highlight     = AppTheme.highlight
        static let danger       = AppTheme.danger

        // Accents
        static let accent     = AppTheme.accent
        static let accentDeep = AppTheme.accentDeep
        static let primary    = AppTheme.accent // brand primary alias

        // Gradients (aliases)
        static var accentGradient: LinearGradient { AppTheme.accentGradient }
        static var capsuleGradient: LinearGradient { AppTheme.capsuleGradient }
        static var pillGradient: LinearGradient { AppTheme.pillGradient }
        static var headerGradient: LinearGradient { AppTheme.headerGradient }
        static var backgroundGradient: LinearGradient { AppTheme.backgroundGradient }

        // Dynamic helpers passthrough
        static func cardBackground(for scheme: ColorScheme) -> Color { AppTheme.cardBackground(for: scheme) }
        static func cardStroke(for scheme: ColorScheme) -> Color { AppTheme.cardStroke(for: scheme) }
        static func tabBarBackground(for scheme: ColorScheme) -> Color { AppTheme.tabBarBackground(for: scheme) }
        static func listBackground(for scheme: ColorScheme) -> Color { AppTheme.listBackground(for: scheme) }
        static func cardGradient(for scheme: ColorScheme) -> LinearGradient { AppTheme.cardGradient(for: scheme) }
    }

    // MARK: - Gradients
    /// Pills, primary CTA
    static var capsuleGradient: LinearGradient { accentGradient }

    /// Large headers / hero areas
    static var headerGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: "#0B1220"), Color(hex: "#1B2A4A"), Color(hex: "#2EC5CE")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Background gradient for screens (deeper than header)
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [backgroundPrimary, backgroundSecondary]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Soft top overlay placed behind large titles to increase readability on images/gradients.
    static var headerReadableOverlay: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.0)]),
            startPoint: .top,
            endPoint: .center
        )
    }

    /// Subtle lift near the bottom safe area so TabBar items stay visible while scrolling.
    static var tabBarLiftOverlay: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.white.opacity(0.0), Color.white.opacity(0.10)]),
            startPoint: .center,
            endPoint: .bottom
        )
    }

    /// Glass card background (choose by scheme in the view)
    static func cardGradient(for scheme: ColorScheme) -> LinearGradient {
        let colors: [Color] = (scheme == .dark)
            ? [Color.white.opacity(0.10), Color.white.opacity(0.02)]
            : [Color.white.opacity(0.95), Color.white.opacity(0.75)]
        return LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: - Simple access aliases (for older call-sites)
    struct SpacingValues {
        let xs: CGFloat = 4
        let s:  CGFloat = 8
        let m:  CGFloat = 12
        let l:  CGFloat = 16
        let xl: CGFloat = 24
    }
    /// Instance-style access (AppTheme.spacing.m) for views that expect a value container.
    static let spacing = SpacingValues()
    /// Common single radius used by cards
    static let cornerRadius: CGFloat = Radius.l

    // Token sets (static). Prefer `AppTheme.spacing` for ergonomic reads in views.
    struct Spacing {
        static let xs: CGFloat = 4
        static let s:  CGFloat = 8
        static let m:  CGFloat = 12
        static let l:  CGFloat = 16
        static let xl: CGFloat = 24
    }

    struct Radius {
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 20
        static let xl: CGFloat = 28
    }

    // Convenience metrics wrapper to group spacing & radius (compat: AppTheme.Metrics.*)
    struct Metrics {
        struct Spacing {
            static let xs = AppTheme.Spacing.xs
            static let s  = AppTheme.Spacing.s
            static let m  = AppTheme.Spacing.m
            static let l  = AppTheme.Spacing.l
            static let xl = AppTheme.Spacing.xl
        }
        struct Radius {
            static let s  = AppTheme.Radius.s
            static let m  = AppTheme.Radius.m
            static let l  = AppTheme.Radius.l
            static let xl = AppTheme.Radius.xl
        }
        static let cornerRadius: CGFloat = AppTheme.cornerRadius
    }

    // MARK: - Shadows (kept subtle for the calm look)
    struct Shadows {
        static var soft: (Color, CGFloat, CGFloat, CGFloat) {
            (Color.black.opacity(0.25), 20, 0, 10)
        }
        static var lifted: (Color, CGFloat, CGFloat, CGFloat) {
            (Color.black.opacity(0.35), 30, 0, 16)
        }
    }

    // MARK: - Fonts
    struct Fonts {
        static let display   = Font.system(size: 34, weight: .bold, design: .rounded)
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title     = Font.system(.title2, design: .rounded).weight(.bold)
        static let title3    = Font.system(.title3, design: .rounded).weight(.semibold)
        static let headline  = Font.system(.headline, design: .rounded)
        static let subheadline = Font.system(.subheadline, design: .rounded)
        static let subtitle  = Font.system(.subheadline, design: .rounded).weight(.medium)
        static let body      = Font.system(.body, design: .rounded)
        static let callout   = Font.system(.callout, design: .rounded)
        static let footnote  = Font.system(.footnote, design: .rounded)
        static let caption   = Font.system(.caption, design: .rounded)
    }
    // Backwards-compat alias used in some files
    static let titleFont = Fonts.title

    // Backwards-compat namespace for typography (AppTheme.Typography.*)
    struct Typography {
        static let display     = Fonts.display
        static let largeTitle  = Fonts.largeTitle
        static let title       = Fonts.title
        static let title3      = Fonts.title3
        static let headline    = Fonts.headline
        static let subheadline = Fonts.subheadline
        static let subtitle    = Fonts.subtitle
        static let body        = Fonts.body
        static let callout     = Fonts.callout
        static let footnote    = Fonts.footnote
        static let caption     = Fonts.caption
    }

    // MARK: - Icons
    struct Icons {
        static let chevronRight = Image(systemName: "chevron.right")
        static let chevronLeft  = Image(systemName: "chevron.left")
        static let play         = Image(systemName: "play.fill")
        static let pause        = Image(systemName: "pause.fill")
    }
    static let chevron = Icons.chevronRight
}

// MARK: - Back-compat shim for legacy `AppTheme.Color.*` tokens
extension AppTheme.Color {
    @available(*, deprecated, message: "Use AppTheme.Colors.iconPrimary instead")
    static var iconPrimary: Color { AppTheme.Colors.iconPrimary }

    @available(*, deprecated, message: "Use AppTheme.Colors.danger instead")
    static var danger: Color { AppTheme.Colors.danger }

    @available(*, deprecated, message: "Use AppTheme.Colors.shadowCard instead")
    static var shadowCard: Color { AppTheme.Colors.shadowCard }
}

// MARK: - Helper Extension for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255,
                            (int >> 8 & 0xF) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
