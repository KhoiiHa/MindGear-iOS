//
//  ConfigManager.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 21.07.25.
//



import Foundation

struct ConfigManager {
    /// Primärer API-Key für YouTube – nur aus Config.plist
    static var youtubeAPIKey: String {
        getValue(for: "YOUTUBE_API_KEY")
    }

    /// Basis-URL für API-Aufrufe, aus der Config gelesen (normalisiert & validiert)
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
            fatalError("❌ API_BASE_URL ungültig – erwarte eine HTTPS-URL mit Host und ohne Pfad/Query/Fragment, z. B. https://api.example.com")
        }

        // Saubere URL ohne impliziten "/"-Pfad zurückgeben
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = parsed.host
        comps.port = parsed.port
        guard let cleanURL = comps.url else {
            fatalError("❌ API_BASE_URL konnte nicht aufgebaut werden")
        }
        return cleanURL
    }

    /// Einheitlicher Resolver (portfolio-clean): nutzt ausschließlich `YOUTUBE_API_KEY` aus Config.plist
    static var resolvedYouTubeAPIKey: String {
        getValue(for: "YOUTUBE_API_KEY")
    }

    @available(*, deprecated, message: "Use youtubeAPIKey instead")
    static var apiKey: String {
        getValue(for: "YOUTUBE_API_KEY")
    }

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

    /// Liste aller bekannten Mentor-Channel-IDs/Handles aus der Config.
    /// Nur vorhandene Keys werden zurückgegeben (kein Crash bei fehlenden Einträgen).
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

    /// Gibt alle Playlist-IDs zurück, die einem Mentor-Channel zugeordnet sind (MENTOR_PLAYLISTS in Config.plist).
    static func playlists(for mentorId: String) -> [String] {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let playlistsDict = dict["MENTOR_PLAYLISTS"] as? [String: Any],
              let arr = playlistsDict[mentorId] as? [String] else {
            return []
        }
        return arr
    }

    /// Liefert den Wert aus Config.plist, falls vorhanden; sonst `nil`.
    private static func getOptionalValue(for key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let value = dict[key] as? String else {
            return nil
        }
        return value
    }


    private static func getValue(for key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let value = dict[key] as? String else {
            fatalError("❌ Config Key '\(key)' not found in Config.plist")
        }
        return value
    }
}
