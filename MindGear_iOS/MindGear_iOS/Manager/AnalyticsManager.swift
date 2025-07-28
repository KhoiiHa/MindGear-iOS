import Foundation

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
