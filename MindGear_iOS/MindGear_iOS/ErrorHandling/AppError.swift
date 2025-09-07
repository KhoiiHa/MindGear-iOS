//
//  AppError.swift
//  MindGear_iOS
//
//  Zweck: Einheitliche Fehlerrepräsentation für Netzwerk, Parsing & generische Fälle.
//  Architekturrolle: Error‑Enum (Business‑nah, aber UI‑freundlich via LocalizedError).
//  Verantwortung: Klare Cases + lokalisierte Fehlermeldungen für User Feedback.
//  Warum? Saubere Fehlerbehandlung ohne verstreute String‑Literals.
//  Testbarkeit: Deterministische Cases; leicht in UnitTests prüfbar.
//  Status: stabil.
//
import Foundation

// Kurzzusammenfassung: Kapselt typische Fehlerfälle (URL, Netzwerk, Decoding, Unknown) mit lokalisierter Meldung.

// MARK: - AppError
/// Einheitliches Error‑Enum für App‑weite Verwendung.
/// Sendable/Equatable → gut für Tests & ViewState.
enum AppError: Error, LocalizedError, Equatable {
    // Grundfälle
    case invalidURL
    case networkError
    case decodingError
    case unknown

    // Erweiterte Fälle
    case httpStatus(Int)                  // z. B. 401, 404, 500
    case timeout                          // Request‑Timeout
    case noData                           // 204/Empty‑Body, obwohl Daten erwartet
    case invalidResponse                  // Kein HTTPURLResponse o. ä.
    case unauthorized                     // Auth/Key fehlt oder ist ungültig
    case rateLimited(retryAfter: Int?)    // 429, optional Retry‑After Sekunden
    case apiKeyMissing                    // API‑Key fehlt in Config
    case underlying(Error)                // Originalfehler für Logs/Debug

    // MARK: LocalizedError
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Die URL ist ungültig."
        case .networkError:
            return "Es ist ein Netzwerkfehler aufgetreten."
        case .decodingError:
            return "Die Daten konnten nicht verarbeitet werden."
        case .timeout:
            return "Die Anfrage hat zu lange gedauert."
        case .noData:
            return "Es wurden keine Daten empfangen."
        case .invalidResponse:
            return "Die Server‑Antwort war ungültig."
        case .unauthorized, .apiKeyMissing:
            return "Zugriff nicht möglich – Berechtigung oder Schlüssel fehlt."
        case .rateLimited:
            return "Zu viele Anfragen in kurzer Zeit."
        case .httpStatus(let code):
            return "Server‑Fehler (Status \(code))."
        case .unknown:
            return "Ein unbekannter Fehler ist aufgetreten."
        case .underlying(let e):
            return (e as NSError).localizedDescription
        }
    }

    var failureReason: String? {
        switch self {
        case .invalidURL:
            return "Die angegebene Adresse konnte nicht gebildet werden."
        case .networkError:
            return "Keine Verbindung oder Netzwerk unterbrochen."
        case .decodingError:
            return "Das empfangene JSON entspricht nicht dem erwarteten Schema."
        case .timeout:
            return "Der Server hat nicht rechtzeitig geantwortet."
        case .noData:
            return "Der Server lieferte einen leeren Inhalt zurück."
        case .invalidResponse:
            return "Antwort war nicht als HTTP interpretierbar."
        case .unauthorized:
            return "Die Anfrage war nicht autorisiert (401/403)."
        case .apiKeyMissing:
            return "Es wurde kein API‑Schlüssel konfiguriert."
        case .rateLimited:
            return "HTTP 429 – Ratenlimit erreicht."
        case .httpStatus(let code):
            return "HTTP Status \(code)."
        case .unknown:
            return nil
        case .underlying:
            return nil
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Bitte die Adresse prüfen."
        case .networkError, .timeout:
            return "Internetverbindung prüfen und später erneut versuchen."
        case .decodingError, .invalidResponse, .noData:
            return "Bitte später erneut versuchen; ggf. App aktualisieren."
        case .unauthorized, .apiKeyMissing:
            return "Anmeldedaten/API‑Schlüssel in den Einstellungen prüfen."
        case .rateLimited(let retry):
            if let s = retry { return "Bitte in \(s) Sekunden erneut versuchen." }
            else { return "Kurz warten und erneut versuchen." }
        case .httpStatus:
            return "Bitte später erneut versuchen."
        case .unknown, .underlying:
            return nil
        }
    }

    // MARK: Convenience
    /// Gruppierung für UI‑Zustände.
    var isNetworkRelated: Bool {
        switch self {
        case .networkError, .timeout, .rateLimited, .httpStatus, .invalidResponse:
            return true
        default:
            return false
        }
    }
}

// MARK: - Mapping
extension AppError {
    /// Heuristische Abbildung gängiger Fehler auf `AppError`.
    static func from(_ error: Error) -> AppError {
        if let app = error as? AppError { return app }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain {
            switch URLError.Code(rawValue: ns.code) {
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost:
                return .networkError
            case .timedOut:
                return .timeout
            case .userAuthenticationRequired, .userCancelledAuthentication:
                return .unauthorized
            default:
                return .underlying(error)
            }
        }
        if error is DecodingError { return .decodingError }
        return .underlying(error)
    }
}

// MARK: - Equatable (custom)
extension AppError {
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.networkError, .networkError),
             (.decodingError, .decodingError),
             (.unknown, .unknown),
             (.timeout, .timeout),
             (.noData, .noData),
             (.invalidResponse, .invalidResponse),
             (.unauthorized, .unauthorized),
             (.apiKeyMissing, .apiKeyMissing):
            return true
        case let (.httpStatus(a), .httpStatus(b)):
            return a == b
        case let (.rateLimited(a), .rateLimited(b)):
            return a == b
        case let (.underlying(le), .underlying(re)):
            let l = le as NSError
            let r = re as NSError
            return l.domain == r.domain && l.code == r.code
        default:
            return false
        }
    }
}

// MARK: - Sendable (unchecked)
// Hinweis: `Error` ist nicht strikt `Sendable`; wir markieren bewusst als unchecked für Concurrency‑Kompatibilität.
extension AppError: @unchecked Sendable {}
