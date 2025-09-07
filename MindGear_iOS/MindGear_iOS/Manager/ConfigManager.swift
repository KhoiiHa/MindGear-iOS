//
//  ConfigManager.swift
//  MindGear_iOS
//
//  Zweck: Zentrale, schreibgeschützte Konfiguration aus `Config.plist` (Single Source of Truth).
//  Architekturrolle: Service/Manager (Key- und URL-Resolver, ohne App-Logik).
//  Verantwortung: API-Keys, Basis-URL-Normalisierung, Mentor-IDs & -Playlists.
//  Warum? Entkoppelt Code von Rohwerten/Strings und verhindert Streuung von Secrets.
//  Testbarkeit: Überladbare Bundle‑Quelle / Test‑Plist möglich; pure Functions erleichtern Mocks.
//  Status: stabil.
//

import Foundation

// Liest Werte aus Config.plist und normalisiert URLs
struct ConfigManager {
    // MARK: - API Keys
    /// Primärer API-Key für YouTube – nur aus Config.plist
    static var youtubeAPIKey: String {
        getValue(for: "YOUTUBE_API_KEY")
    }

    // MARK: - Basis-URL
    /// Liefert die normalisierte Basis‑URL (erzwingt HTTPS, entfernt Slashes/Query/Fragment).
    /// Warum: Einheitliche, sichere Basis für API‑Clients; vermeidet subtile Pfadfehler.
    static func apiBaseURL() -> URL {
        var raw = getValue(for: "API_BASE_URL").trimmingCharacters(in: .whitespacesAndNewlines)

        // trailing Slash entfernen
        while raw.hasSuffix("/") { raw.removeLast() }

        // http -> https umschreiben
        if raw.lowercased().hasPrefix("http://") {
            raw = "https://" + raw.dropFirst("http://".count)
        }

        // Parsen & Regeln prüfen
        guard let parsed = URL(string: raw),
              let scheme = parsed.scheme?.lowercased(), scheme == "https",
              let host = parsed.host, !host.isEmpty,
              (parsed.path.isEmpty || parsed.path == "/"),
              parsed.query == nil,
              parsed.fragment == nil
        else {
            // Fail‑fast im Dev: Falsche Plist‑Konfiguration sofort sichtbar machen.
            fatalError("❌ API_BASE_URL ungültig – erwarte eine HTTPS-URL mit Host und ohne Pfad/Query/Fragment, z. B. https://api.example.com")
        }

        // Saubere URL ohne impliziten "/"-Pfad zurückgeben
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = parsed.host
        comps.port = parsed.port
        guard let cleanURL = comps.url else {
            // Defensive: Sollte bei gültigen Komponenten nie auftreten – bewusst hart abbrechen.
            fatalError("❌ API_BASE_URL konnte nicht aufgebaut werden")
        }
        return cleanURL
    }

    /// Einheitlicher Resolver für den YouTube‑API‑Key.
    /// Warum: Verhindert alternative Quellen; `Config.plist` bleibt einzige Wahrheit.
    static var resolvedYouTubeAPIKey: String {
        getValue(for: "YOUTUBE_API_KEY")
    }

    @available(*, deprecated, message: "Nutze `youtubeAPIKey` – Config.plist ist die alleinige Quelle")
    static var apiKey: String {
        getValue(for: "YOUTUBE_API_KEY")
    }

    // MARK: - Mentor IDs
    static var chrisWillxChannelId: String {
        return getValue(for: "CHRISWILLX_CHANNEL_ID")
    }

    static var jayShettyChannelId: String {
        return getValue(for: "JAYSHETTY_CHANNEL_ID")
    }

    static var shiHengYiChannelId: String? { getOptionalValue(for: "SHIHENGYI_CHANNEL_ID") }
    static var lexFridmanChannelId: String? { getOptionalValue(for: "LEXFRIDMAN_CHANNEL_ID") }
    static var diaryOfACEOChannelId: String? { getOptionalValue(for: "DIARYOFACEO_CHANNEL_ID") }
    static var shawnRyanChannelId: String? { getOptionalValue(for: "SHAWNRYAN_CHANNEL_ID") }
    static var jordanBPetersonChannelId: String? { getOptionalValue(for: "JORDANBPETERSON_CHANNEL_ID") }
    static var simonSinekChannelId: String? { getOptionalValue(for: "SIMONSINEK_CHANNEL_ID") }
    static var theoVonChannelId: String? { getOptionalValue(for: "THEOVON_CHANNEL_ID") }

    /// Konsolidierte Liste aller vorhandenen Channel‑Tokens (IDs oder Handles) aus der Config.
    /// Warum: UI/ViewModels können dynamisch über vorhandene Einträge iterieren; keine Hard‑Codierung.
    static var mentorChannelTokens: [String] {
        var tokens: [String] = []
        tokens.append(chrisWillxChannelId)
        tokens.append(jayShettyChannelId)
        if let v = shiHengYiChannelId { tokens.append(v) }
        if let v = lexFridmanChannelId { tokens.append(v) }
        if let v = diaryOfACEOChannelId { tokens.append(v) }
        if let v = shawnRyanChannelId { tokens.append(v) }
        if let v = jordanBPetersonChannelId { tokens.append(v) }
        if let v = simonSinekChannelId { tokens.append(v) }
        if let v = theoVonChannelId { tokens.append(v) }
        return tokens
    }

    static var shawnRyanPlaylistId: String {
        return getValue(for: "SHAWNRYAN_PLAYLIST")
    }

    static var jayShettyPlaylistId: String {
        return getValue(for: "JAYSHETTY_PLAYLIST")
    }

    static var recommendedPlaylistId: String {
        return getValue(for: "RECOMMENDED_PLAYLIST")
    }

    static var diaryOfACeoPlaylistId: String {
        return getValue(for: "DIARYOFACEO_PLAYLIST")
    }

    static var theoVonPlaylistId: String {
        return getValue(for: "THEOVON_PLAYLIST")
    }

    static var jordanBPetersonPlaylistId: String {
        return getValue(for: "JORDANBPETERSON_PLAYLIST")
    }

    static var simonSinekPlaylistId: String {
        return getValue(for: "SIMONSINEK_PLAYLIST")
    }

    static var shiHengYiPlaylistId: String {
        return getValue(for: "SHIHENGYI_PLAYLIST")
    }

    // MARK: - Mentor Playlists
    /// Gibt alle Playlist‑IDs zu einem Mentor‑Token zurück.
    /// Warum: Defensive Rückgabe – fehlende Keys liefern `[]` statt Crash; robuste UI‑Anbindung.
    static func playlists(for mentorId: String) -> [String] {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let playlistsDict = dict["MENTOR_PLAYLISTS"] as? [String: Any],
              let arr = playlistsDict[mentorId] as? [String] else {
            return []
        }
        return arr
    }

    // MARK: - Helpers
    /// Liefert den Wert aus Config.plist, falls vorhanden; sonst `nil`.
    /// Warum: Für optionale Konfigurationswerte (nicht kritisch für den App‑Start).
    private static func getOptionalValue(for key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let value = dict[key] as? String else {
            return nil
        }
        return value
    }

    /// Liefert einen verpflichtenden Wert aus Config.plist.
    /// Warum: Fail‑fast bei Fehlkonfiguration – vermeidet stille, schwer auffindbare Fehler.
    private static func getValue(for key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let value = dict[key] as? String else {
              // Fail‑fast: Fehlender Pflicht‑Key – Crash im Dev, um Integrationsfehler früh zu sehen.
            fatalError("❌ Config Key '\(key)' not found in Config.plist")
        }
        return value
    }
}
