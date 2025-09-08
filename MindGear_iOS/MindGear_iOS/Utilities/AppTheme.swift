//
//  AppTheme.swift
//  MindGear_iOS
//
//  Zweck: Zentrale Design‑Tokens (Farben, Typografie, Abstände, Radien, Gradients) für konsistentes UI.
//  Architekturrolle: Utility (präsentationsnah, keine Geschäftslogik).
//  Verantwortung: Benannte Tokens & Gradients, Backwards‑Compat‑Aliases, dynamische Helper pro ColorScheme.
//  Warum? Einheitlicher Look & Feel; vermeidet „Magic Numbers“ & Streuung von Hex‑Strings in Views.
//  Testbarkeit: Deterministische Konstanten; Previews/UITests profitieren von stabilen Werten.
//  Status: stabil.
//

import SwiftUI

// Kurzzusammenfassung: Calm/modern Look (blue/violet + glass) mit klaren Tokens & Backwards‑Compat‑Namespaces.

/// Zentrale Design‑Tokens (Farben, Spacing, Radien, Fonts, Gradients)
/// Schlank & lesbar; Moodboard: blau/violett + „glass look“
struct AppTheme {
    // Warum: Einfache, benannte Farben statt verstreuter Hex‑Strings; Dark‑optimiert
    // MARK: - Colors
    static let backgroundPrimary   = Color(hex: "#070A15")
    static let backgroundSecondary = Color(hex: "#0B1225")
    static let background = backgroundPrimary
    // Subtile Glass‑Surface (Dark) – erhöht Lesbarkeit ohne starke Kontraste
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
    // Brand‑Verlauf für CTAs (Primary)
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "#4B3F9E"), Color(hex: "#3A2D7A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    // Alias: „Pill“ nutzt denselben Verlauf wie Capsule (Button‑Style)
    static var pillGradient: LinearGradient { capsuleGradient }
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    // Scheme-aware Textfarben – vermeiden harte Weißbindung im Light Mode
    static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white : Color.primary
    }
    static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.78) : Color.secondary
    }
    static func textTertiary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.5) : Color.secondary.opacity(0.8)
    }
    /// Alias for older call-sites
    public static let secondary = textSecondary
    static let secondaryText = textSecondary
    static let highlight = Color(hex: "#C084FC")

    // Legacy tokens used in older views (kept for back-compat)
    // Legacy/Alert‑Farbe – bewusst sparsam einsetzen
    static let danger = Color(hex: "#EF4444")
    static let shadowCard = Color.black.opacity(0.25)

    /// Dynamischer Karten‑Hintergrund (Glass in Dark, leichte Tönung in Light).
    /// Warum: Verhindert harte Blöcke; bleibt lesbar.
    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? surfaceElevated : Color.black.opacity(0.05)
    }

    /// Subtiler Rand für „Glass Look“.
    /// Warum: Bessere Abgrenzung ohne sichtbares „Rahmen‑Gefühl“.
    static func cardStroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.08)
    }

    /// Stabile TabBar‑Fläche (gegen UIKit‑Transluzenz/White‑Bleed).
    static func tabBarBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? backgroundPrimary : Color.white
    }
    static func listBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? backgroundSecondary : Color.white
    }

    // MARK: - Color namespace (backwards-compat for AppTheme.Colors.*)
    // Warum: Backwards‑Compat für ältere Call‑Sites (AppTheme.Colors.*)
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
    /// Pills / Primary CTA
    static var capsuleGradient: LinearGradient { accentGradient }

    // Große Header/Hero‑Flächen – tiefer Verlauf mit dezentem Cyan‑Akzent
    static var headerGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#0B1220"),
                Color(hex: "#1B2A4A"),
                Color(hex: "#1FA4AD") // vorher: #2EC5CE
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Screen‑Hintergrund (ruhig, dunkel)
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [backgroundPrimary, backgroundSecondary]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Lesbarkeits‑Overlay hinter großen Titeln auf Bildern/Verläufen.
    /// Warum: Erhöht Kontrast ohne Box zu zeichnen.
    static var headerReadableOverlay: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.0)]),
            startPoint: .top,
            endPoint: .center
        )
    }

    /// Sanfte Aufhellung am unteren Rand.
    /// Warum: TabBar‑Items bleiben sichtbar beim Scrollen.
    static var tabBarLiftOverlay: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.white.opacity(0.0), Color.white.opacity(0.02)]),
            startPoint: .center,
            endPoint: .bottom
        )
    }

    /// Glass‑Card Gradient je Scheme.
    /// Warum: Dark = transparent; Light = opak genug für Kontrast.
    static func cardGradient(for scheme: ColorScheme) -> LinearGradient {
        let colors: [Color] = (scheme == .dark)
            ? [Color.white.opacity(0.10), Color.white.opacity(0.02)]
            : [Color.white.opacity(0.95), Color.white.opacity(0.75)]
        return LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Ergonomischer Zugriff (Instanz‑Style) für Views
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

    // Token‑Set (statisch) – bevorzugt `AppTheme.spacing` im View‑Code
    struct Spacing {
        static let xs: CGFloat = 4
        static let s:  CGFloat = 8
        static let m:  CGFloat = 12
        static let l:  CGFloat = 16
        static let xl: CGFloat = 24
    }

    // Radien für Cards/Controls (calm look → runder)
    struct Radius {
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 20
        static let xl: CGFloat = 28
    }

    // Kompatibilitäts‑Wrapper für ältere Call‑Sites
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

    // Dezente Schatten – vermeiden visuelles Rauschen
    struct Shadows {
        static var soft: (Color, CGFloat, CGFloat, CGFloat) {
            (Color.black.opacity(0.12), 12, 0, 6)
        }
        static var lifted: (Color, CGFloat, CGFloat, CGFloat) {
            (Color.black.opacity(0.18), 20, 0, 10)
        }
    }

    // Bewegungs-Tokens für konsistente, ruhige Micro-Interactions
    struct Motion {
        static let tapScale: CGFloat = 0.98
        static let tapDuration: Double = 0.12
        static let appear: Animation = .easeOut(duration: 0.20)
    }

    // Häufig genutzte SF Symbols als zentrale Referenzen
    struct Icons {
        static let chevronRight = Image(systemName: "chevron.right")
        static let chevronLeft  = Image(systemName: "chevron.left")
        static let play         = Image(systemName: "play.fill")
        static let pause        = Image(systemName: "pause.fill")
    }
    static let chevron = Icons.chevronRight
    // MARK: - Legacy Namespace
    /// Backwards‑compat: `AppTheme.Color` verweist direkt auf `SwiftUI.Color` (voll kompatibel: .white/.black/Init)
    typealias Color = SwiftUI.Color
}

// MARK: - Back-compat shim for legacy `AppTheme.Color.*` tokens
// Warum: Alte Aufrufe weiter unterstützen, ohne Breaking Changes
extension AppTheme.Color {
    @available(*, deprecated, message: "Use AppTheme.Colors.iconPrimary instead")
    static var iconPrimary: Color { AppTheme.Colors.iconPrimary }

    @available(*, deprecated, message: "Use AppTheme.Colors.danger instead")
    static var danger: Color { AppTheme.Colors.danger }

    @available(*, deprecated, message: "Use AppTheme.Colors.shadowCard instead")
    static var shadowCard: Color { AppTheme.Colors.shadowCard }
}

// MARK: - Helper Extension for Hex Colors
/// Erlaubt `Color(hex: "#RRGGBB"/"#AARRGGBB") mit robustem Fallback.
/// Warum: Verhindert fehleranfällige, verstreute Scanner‑Snippets.
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
