import Foundation

// ANALYTICS MANAGER
// prepared for future SDK integration (e.g., Firebase Analytics, TelemetryDeck)
// Central point to track events across the app.
//
// TODOs for future:
// - Track screen opens (Home, Mentoren, Playlists, Settings)
// - Track user interactions (Favorite toggled, Video play, Search used)
// - Integrate with privacy settings (opt-in/out)

/// Central logging and analytics handler used throughout the app.
final class AnalyticsManager {
    static let shared = AnalyticsManager()
    private init() {}

    /// Logs a custom event. Real analytics integration will follow later.
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        // TODO: Connect to analytics SDK
        print("[Analytics] \(name): \(parameters ?? [:])")
    }
}
