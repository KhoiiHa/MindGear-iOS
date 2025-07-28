import SwiftUI

/// Central place for colors and fonts to prepare Dark Mode and design tweaks.
struct AppTheme {
    /// Primary brand color used across the app.
    static var accentColor: Color {
        Color("AccentColor")
    }

    /// Background color that adapts to light and dark mode.
    static var background: Color {
        Color("BackgroundColor")
    }

    /// Standard typography styles.
    struct Fonts {
        static let title = Font.system(size: 28, weight: .bold, design: .default)
        static let body = Font.system(size: 16)
    }
}
