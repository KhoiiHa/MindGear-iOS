import Foundation

// Zentraler Logger für zukünftige Analytics-Integrationen
final class AnalyticsManager {
    static let shared = AnalyticsManager()
    private init() {}

    // MARK: - Public API
    /// Protokolliert ein Ereignis (derzeit nur Konsole)
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        // TODO: Connect to analytics SDK
        print("[Analytics] \(name): \(parameters ?? [:])")
    }
}
