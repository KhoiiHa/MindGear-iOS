//
//  AnalyticsManager.swift
//  MindGear_iOS
//
//  Zweck: Einheitliches Event- & Screen-Tracking ohne direkte SDK-Kopplung.
//  Architekturrolle: Service/Manager (Fassade über austauschbare Provider).
//  Verantwortung: Stable API für Logging, Provider-Registrierung, Fail‑Safe im DEBUG.
//  Warum? Verhindert SDK-Leaks in Views/ViewModels und erlaubt späteren Anbieterwechsel.
//  Testbarkeit: Über `AnalyticsProvider` leicht zu mocken; Call-Sites bleiben unverändert.
//  Status: prepared for future SDK integration.
//
import Foundation

// MARK: - Implementierung: AnalyticsManager
// Zentraler Einstiegspunkt für Analytics/Logging.
// Ziel: Eine schlanke, austauschbare Schicht, die heute nur in die Konsole schreibt
// (DEBUG-Builds), morgen aber einfach an ein SDK (z. B. Firebase, Amplitude) 
// angeschlossen werden kann.
//
// Vorteile:
// • Eine API für die App – Call-Sites bleiben stabil
// • Mehrere Provider möglich (z. B. Konsole + externes SDK)
// • In Release-Builds kein unnötiges Console Logging

final class AnalyticsManager {
    static let shared = AnalyticsManager()
    private init() {
        // Warum: Fail‑Safe Default im DEBUG – sofortiges Feedback ohne SDK; in Release stumm.
        #if DEBUG
        register(ConsoleAnalyticsProvider())
        #endif
    }

    // Interne Liste der aktiven Provider (z. B. Konsole, Firebase, …)
    private var providers: [AnalyticsProvider] = []

    // MARK: - Configuration
    /// Registriert einen zusätzlichen Provider (Komposition statt Kopplung).
    /// Warum: Call-Sites bleiben stabil, mehrere Backends parallel möglich (z. B. Konsole + SDK).
    /// - Parameter provider: Eine `AnalyticsProvider`-Implementierung
    func register(_ provider: AnalyticsProvider) {
        providers.append(provider)
    }

    // MARK: - Public API
    /// Protokolliert ein generisches Ereignis.
    /// Warum: Einheitliche, abwärtskompatible API – konkrete Backends bleiben austauschbar.
    /// - Parameters:
    ///   - name: Ereignisname (z. B. "video_play" / "favorites_toggle")
    ///   - parameters: optionale Details zum Ereignis
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        providers.forEach { $0.logEvent(name, parameters: parameters) }
    }

    /// Convenience: Screen-Aufrufe protokollieren.
    /// Warum: Konsistente Screen-Namen; spätere Auto-Screenview-Integration möglich.
    func logScreen(_ name: String) {
        logEvent("screen_view", parameters: ["screen": name])
    }

    /// Convenience: Nicht-abstürzende Fehler protokollieren.
    /// Warum: Sichtbarkeit für Probleme ohne Crashlytics-Zwang; Context via `info`.
    func logError(_ message: String, info: [String: Any]? = nil) {
        var params = info ?? [:]
        params["message"] = message
        logEvent("error_nonfatal", parameters: params)
    }
}

// MARK: - Protokoll(e)
/// Abstraktion für konkrete Analytics-Backends (mockbar in Tests).
protocol AnalyticsProvider {
    func logEvent(_ name: String, parameters: [String: Any]?)
}

// MARK: - Default Provider
/// DEBUG-Only Provider: schreibt Events in die Konsole; in Release stumm.
struct ConsoleAnalyticsProvider: AnalyticsProvider {
    func logEvent(_ name: String, parameters: [String: Any]?) {
        #if DEBUG
        let params = parameters ?? [:]
        print("[Analytics] \(name): \(params)")
        #endif
    }
}
