import Foundation

// YouTube-Fehlerhülle zum Dekodieren von Fehlerantworten
struct YouTubeAPIErrorEnvelope: Decodable, Error {
    struct Inner: Decodable { let code: Int; let message: String }
    let error: Inner
}

protocol APIServiceProtocol {
    /// Lädt YouTube-PlaylistItems. Optionaler pageToken ermöglicht Pagination.
    func fetchVideos(from playlistId: String, apiKey: String, pageToken: String?) async throws -> YouTubeResponse

    /// Sucht YouTube-Videos. Optionaler pageToken ermöglicht Pagination.
    func searchVideos(query: String, apiKey: String, pageToken: String?) async throws -> YouTubeSearchResponse
}

// MARK: - Einfache In-Memory-Response-Cache + Request-Bündelung (pro App-Session)
private struct CacheKey: Hashable {
    let playlistId: String
    let pageToken: String?
}

private actor ResponseCache {
    private var store: [CacheKey: YouTubeResponse] = [:]
    private var inflight: [CacheKey: Task<YouTubeResponse, Error>] = [:]

    func value(for key: CacheKey) -> YouTubeResponse? { store[key] }
    func set(_ value: YouTubeResponse, for key: CacheKey) { store[key] = value }

    func task(for key: CacheKey) -> Task<YouTubeResponse, Error>? { inflight[key] }
    func setTask(_ task: Task<YouTubeResponse, Error>?, for key: CacheKey) { inflight[key] = task }
    func removeTask(for key: CacheKey) { inflight.removeValue(forKey: key) }
    func clear() { store.removeAll(); inflight.removeAll() }
}

final class APIService: APIServiceProtocol {
    static let shared = APIService()
    private static let cache = ResponseCache()

    private static let session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        var headers: [AnyHashable: Any] = [
            "User-Agent": "MindGear-iOS/1.0",
            "Accept": "application/json"
        ]
        // Merge with any pre-set headers if present
        if let existing = cfg.httpAdditionalHeaders {
            for (k, v) in existing { headers[k] = v }
        }
        cfg.httpAdditionalHeaders = headers
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest = 30
        cfg.timeoutIntervalForResource = 60
        return URLSession(configuration: cfg)
    }()

    private init() {}

    // Führt den tatsächlichen Netzwerkabruf aus (ohne Cache/Koaleszierung)
    private func performNetworkFetch(playlistId: String, apiKey: String, pageToken: String?) async throws -> YouTubeResponse {
        // Versuche beide bekannten Hosts, um Probleme mit Edge-Netzwerken zu umgehen
        let hosts = [
            "https://www.googleapis.com/youtube/v3/playlistItems",
            "https://youtube.googleapis.com/youtube/v3/playlistItems"
        ]


        var lastError: Error = AppError.networkError

        for endpoint in hosts {
            var attempt = 0
            while attempt < 3 { // retry up to 3x per host
                attempt += 1
                do {
                    var components = URLComponents(string: endpoint)!
                    components.queryItems = [
                        URLQueryItem(name: "part", value: "snippet,contentDetails"),
                        URLQueryItem(name: "maxResults", value: "10"),
                        URLQueryItem(name: "playlistId", value: playlistId),
                        URLQueryItem(name: "key", value: apiKey),
                        URLQueryItem(name: "prettyPrint", value: "false"),
                        URLQueryItem(name: "alt", value: "json")
                    ]
                    if let pageToken, !pageToken.isEmpty {
                        components.queryItems?.append(URLQueryItem(name: "pageToken", value: pageToken))
                    }
                    guard let url = components.url else { throw AppError.invalidURL }

                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.setValue("application/json", forHTTPHeaderField: "Accept")
                    request.cachePolicy = .reloadIgnoringLocalCacheData

                    #if DEBUG
                    print("🔎 URL:", url.absoluteString)
                    #endif

                    let (data, response) = try await APIService.session.data(for: request)

                    #if DEBUG
                    if let http = response as? HTTPURLResponse {
                        print("🌐 STATUS:", http.statusCode)
                        print("🌐 HEADERS:", http.allHeaderFields)
                    }
                    #endif

                    // HTML erkennen (Zustimmungs-/Blockierungsseiten)
                    if let text = String(data: data.prefix(200), encoding: .utf8),
                       text.contains("<html") || text.contains("<!DOCTYPE html") {
                        let preview = String(data: data.prefix(400), encoding: .utf8) ?? "<non-utf8>"
                        print("❗️HTML statt JSON. KÖRPER-Vorschau:\n\(preview)")
                        lastError = AppError.networkError
                        break // do not retry HTML response on same host, try next host
                    }

                    // Nicht 2xx: Versuche, die YouTube-Fehlerhülle für bessere Diagnose zu dekodieren
                    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        if let yt = try? JSONDecoder().decode(YouTubeAPIErrorEnvelope.self, from: data) {
                            print("❗️YouTube API-Fehler:", yt.error.code, yt.error.message)
                        } else {
                            let preview = String(data: data.prefix(400), encoding: .utf8) ?? "<non-utf8>"
                            print("❗️HTTP \(http.statusCode). KÖRPER-Vorschau:\n\(preview)")
                        }
                        lastError = AppError.networkError
                        break // do not retry HTTP error on same host, try next host
                    }

                    // Erfolgreicher Pfad: Elemente dekodieren
                    do {
                        let response = try JSONDecoder().decode(YouTubeResponse.self, from: data)
                        return response
                    } catch {
                        let preview = String(data: data.prefix(400), encoding: .utf8) ?? "<non-utf8>"
                        print("❗️Dekodierung fehlgeschlagen. KÖRPER-Vorschau:\n\(preview)")
                        lastError = AppError.decodingError
                        break // do not retry decoding error on same host, try next host
                    }
                } catch {
                    print("❗️Transportfehler (Attempt #\(attempt)):", error.localizedDescription)
                    lastError = error

                    if let urlError = error as? URLError {
                        switch urlError.code {
                        case .cannotParseResponse, .badServerResponse:
                            // Nicht auf gleichem Host weiterversuchen → brechen und den nächsten Host probieren
                            break
                        case .timedOut, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .notConnectedToInternet:
                            let delay = pow(2.0, Double(attempt - 1)) * 0.5 // 0.5s, 1s, 2s
                            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            continue // Retry auf gleichem Host
                        default:
                            break // Unbekannt/irrelevant → nächsten Host versuchen
                        }
                    }
                    // Für alle anderen Fehler: zum nächsten Host wechseln
                    break
                }
            }
            // if we exit the while without returning, try next host
        }

        throw lastError
    }

    // Führt den tatsächlichen Netzwerkabruf für die YouTube-Suche aus (ohne Cache/Koaleszierung)
    private func performSearchFetch(query: String, apiKey: String, pageToken: String?) async throws -> YouTubeSearchResponse {
        let hosts = [
            "https://www.googleapis.com/youtube/v3/search",
            "https://youtube.googleapis.com/youtube/v3/search"
        ]
        var lastError: Error = AppError.networkError

        for endpoint in hosts {
            var attempt = 0
            while attempt < 3 {
                attempt += 1
                do {
                    var components = URLComponents(string: endpoint)!
                    components.queryItems = [
                        URLQueryItem(name: "part", value: "snippet"),
                        URLQueryItem(name: "maxResults", value: "10"),
                        URLQueryItem(name: "q", value: query),
                        URLQueryItem(name: "type", value: "video"),
                        URLQueryItem(name: "key", value: apiKey),
                        URLQueryItem(name: "prettyPrint", value: "false"),
                        URLQueryItem(name: "alt", value: "json")
                    ]
                    if let pageToken, !pageToken.isEmpty {
                        components.queryItems?.append(URLQueryItem(name: "pageToken", value: pageToken))
                    }
                    guard let url = components.url else { throw AppError.invalidURL }

                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.setValue("application/json", forHTTPHeaderField: "Accept")
                    request.cachePolicy = .reloadIgnoringLocalCacheData

                    #if DEBUG
                    print("🔎 SEARCH URL:", url.absoluteString)
                    #endif

                    let (data, response) = try await APIService.session.data(for: request)

                    #if DEBUG
                    if let http = response as? HTTPURLResponse {
                        print("🌐 STATUS:", http.statusCode)
                        print("🌐 HEADERS:", http.allHeaderFields)
                    }
                    #endif

                    if let text = String(data: data.prefix(200), encoding: .utf8),
                       text.contains("<html") || text.contains("<!DOCTYPE html") {
                        let preview = String(data: data.prefix(400), encoding: .utf8) ?? "<non-utf8>"
                        print("❗️HTML statt JSON (Search). Vorschau:\n\(preview)")
                        lastError = AppError.networkError
                        break
                    }

                    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        if let yt = try? JSONDecoder().decode(YouTubeAPIErrorEnvelope.self, from: data) {
                            print("❗️YouTube SEARCH-Fehler:", yt.error.code, yt.error.message)
                        } else {
                            let preview = String(data: data.prefix(400), encoding: .utf8) ?? "<non-utf8>"
                            print("❗️HTTP \(http.statusCode). SEARCH KÖRPER-Vorschau:\n\(preview)")
                        }
                        lastError = AppError.networkError
                        break
                    }

                    do {
                        let response = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
                        return response
                    } catch {
                        let preview = String(data: data.prefix(400), encoding: .utf8) ?? "<non-utf8>"
                        print("❗️Dekodierung fehlgeschlagen (Search). Vorschau:\n\(preview)")
                        lastError = AppError.decodingError
                        break
                    }
                } catch {
                    print("❗️Transportfehler SEARCH (Attempt #\(attempt)):", error.localizedDescription)
                    lastError = error
                    if let urlError = error as? URLError {
                        switch urlError.code {
                        case .cannotParseResponse, .badServerResponse:
                            break
                        case .timedOut, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .notConnectedToInternet:
                            let delay = pow(2.0, Double(attempt - 1)) * 0.5
                            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            continue
                        default:
                            break
                        }
                    }
                    break
                }
            }
        }
        throw lastError
    }

    func fetchVideos(from playlistId: String, apiKey: String, pageToken: String?) async throws -> YouTubeResponse {
        let key = CacheKey(playlistId: playlistId, pageToken: pageToken)

        // 1) Cache-Hit? Direkt zurückgeben
        if let cached = await APIService.cache.value(for: key) {
            print("💾 Cache-Hit für", key)
            return cached
        }

        // 2) Läuft für diesen Key schon eine Anfrage? → mit dranhängen
        if let running = await APIService.cache.task(for: key) {
            print("🤝 Anfrage gebündelt – warte auf bestehende Task")
            return try await running.value
        }

        // 3) Eigene Anfrage starten, im inflight-Register ablegen
        let task = Task { () throws -> YouTubeResponse in
            try await self.performNetworkFetch(playlistId: playlistId, apiKey: apiKey, pageToken: pageToken)
        }
        await APIService.cache.setTask(task, for: key)

        do {
            let response = try await task.value
            await APIService.cache.set(response, for: key)
            await APIService.cache.removeTask(for: key)
            print("✅ Netzwerk → Cache gespeichert für", key)
            return response
        } catch {
            await APIService.cache.removeTask(for: key)
            throw error
        }
    }

    // MARK: - Suche (ohne Session-Cache, bewusst einfach gehalten)
    func searchVideos(query: String, apiKey: String, pageToken: String?) async throws -> YouTubeSearchResponse {
        try await performSearchFetch(query: query, apiKey: apiKey, pageToken: pageToken)
    }

    // MARK: - Channels (YouTube Channel Lookup without cache)
    // Low-level fetch that mirrors the retry/diagnostic style of the other endpoints.
    private func performChannelFetch(queryItems: [URLQueryItem]) async throws -> YouTubeChannelListResponse {
        let hosts = [
            "https://www.googleapis.com/youtube/v3/channels",
            "https://youtube.googleapis.com/youtube/v3/channels"
        ]
        var lastError: Error = AppError.networkError

        for endpoint in hosts {
            var attempt = 0
            while attempt < 3 {
                attempt += 1
                do {
                    var components = URLComponents(string: endpoint)!
                    components.queryItems = queryItems + [
                        URLQueryItem(name: "prettyPrint", value: "false"),
                        URLQueryItem(name: "alt", value: "json")
                    ]
                    guard let url = components.url else { throw AppError.invalidURL }

                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.setValue("application/json", forHTTPHeaderField: "Accept")
                    request.cachePolicy = .reloadIgnoringLocalCacheData

                    #if DEBUG
                    print("🔎 CHANNEL URL:", url.absoluteString)
                    #endif

                    let (data, response) = try await APIService.session.data(for: request)

                    #if DEBUG
                    if let http = response as? HTTPURLResponse {
                        print("🌐 STATUS:", http.statusCode)
                        print("🌐 HEADERS:", http.allHeaderFields)
                    }
                    #endif

                    if let text = String(data: data.prefix(200), encoding: .utf8),
                       text.contains("<html") || text.contains("<!DOCTYPE html") {
                        let preview = String(data: data.prefix(400), encoding: .utf8) ?? "<non-utf8>"
                        print("❗️HTML statt JSON (Channels). Vorschau:\n\(preview)")
                        lastError = AppError.networkError
                        break
                    }

                    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        if let yt = try? JSONDecoder().decode(YouTubeAPIErrorEnvelope.self, from: data) {
                            print("❗️YouTube CHANNEL-Fehler:", yt.error.code, yt.error.message)
                        } else {
                            let preview = String(data: data.prefix(400), encoding: .utf8) ?? "<non-utf8>"
                            print("❗️HTTP \(http.statusCode). CHANNEL KÖRPER-Vorschau:\n\(preview)")
                        }
                        lastError = AppError.networkError
                        break
                    }

                    do {
                        let response = try JSONDecoder().decode(YouTubeChannelListResponse.self, from: data)
                        return response
                    } catch {
                        let preview = String(data: data.prefix(400), encoding: .utf8) ?? "<non-utf8>"
                        print("❗️Dekodierung fehlgeschlagen (Channels). Vorschau:\n\(preview)")
                        lastError = AppError.decodingError
                        break
                    }
                } catch {
                    print("❗️Transportfehler CHANNELS (Attempt #\(attempt)):", error.localizedDescription)
                    lastError = error
                    if let urlError = error as? URLError {
                        switch urlError.code {
                        case .cannotParseResponse, .badServerResponse:
                            break
                        case .timedOut, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .notConnectedToInternet:
                            let delay = pow(2.0, Double(attempt - 1)) * 0.5
                            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            continue
                        default:
                            break
                        }
                    }
                    break
                }
            }
        }
        throw lastError
    }

    // Strips any leading '@' from a handle string to keep callers flexible
    private func sanitizeHandle(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("@") {
            return String(trimmed.drop(while: { $0 == "@" }))
        }
        return trimmed
    }

    /// Convenience: Channel über Handle (ohne @-Zeichen übergeben: "ShiHengYiOnline")
    func fetchChannel(byHandle handle: String, apiKey: String) async throws -> YouTubeChannelListResponse {
        try await performChannelFetch(queryItems: [
            URLQueryItem(name: "part", value: "snippet,statistics"),
            URLQueryItem(name: "forHandle", value: "@\(sanitizeHandle(handle))"),
            URLQueryItem(name: "key", value: apiKey)
        ])
    }

    /// Convenience: Channel über Channel-ID (z. B. "UC...")
    func fetchChannel(byId channelId: String, apiKey: String) async throws -> YouTubeChannelListResponse {
        try await performChannelFetch(queryItems: [
            URLQueryItem(name: "part", value: "snippet,statistics"),
            URLQueryItem(name: "id", value: channelId),
            URLQueryItem(name: "key", value: apiKey)
        ])
    }

    /// Convenience: Versucht zuerst per Channel-ID, fällt bei Bedarf auf Handle zurück und gibt das erste Item
    func fetchChannel(preferId channelId: String?, handle: String?, apiKey: String) async throws -> YouTubeChannelItem {
        if let id = channelId, !id.isEmpty {
            let resp = try await fetchChannel(byId: id, apiKey: apiKey)
            if let first = resp.items.first { return first }
        }
        if let h = handle, !h.isEmpty {
            let resp = try await fetchChannel(byHandle: h, apiKey: apiKey)
            if let first = resp.items.first { return first }
        }
        throw AppError.networkError
    }

    // MARK: - Playlist Info (YouTube Playlist Lookup)
    func fetchPlaylistInfo(playlistId: String, apiKey: String = ConfigManager.youtubeAPIKey) async throws -> PlaylistInfo {
        let hosts = [
            "https://www.googleapis.com/youtube/v3/playlists",
            "https://youtube.googleapis.com/youtube/v3/playlists"
        ]
        var lastError: Error = AppError.networkError

        for endpoint in hosts {
            var attempt = 0
            while attempt < 3 {
                attempt += 1
                do {
                    var components = URLComponents(string: endpoint)!
                    components.queryItems = [
                        URLQueryItem(name: "part", value: "snippet"),
                        URLQueryItem(name: "id", value: playlistId),
                        URLQueryItem(name: "key", value: apiKey),
                        URLQueryItem(name: "prettyPrint", value: "false"),
                        URLQueryItem(name: "alt", value: "json")
                    ]
                    guard let url = components.url else { throw AppError.invalidURL }

                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.setValue("application/json", forHTTPHeaderField: "Accept")
                    request.cachePolicy = .reloadIgnoringLocalCacheData

                    let (data, response) = try await APIService.session.data(for: request)

                    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        lastError = AppError.networkError
                        break
                    }

                    struct PlaylistResponse: Decodable {
                        struct Item: Decodable {
                            let id: String
                            let snippet: Snippet
                        }
                        struct Snippet: Decodable {
                            let title: String
                            let description: String
                            let thumbnails: [String: YouTubeThumbImage]?
                        }
                        let items: [Item]
                    }

                    let decoded = try JSONDecoder().decode(PlaylistResponse.self, from: data)
                    if let first = decoded.items.first {
                        let thumbUrl = first.snippet.thumbnails?["medium"]?.url ?? first.snippet.thumbnails?["default"]?.url ?? ""
                        return PlaylistInfo(
                            title: first.snippet.title,
                            subtitle: first.snippet.description,
                            iconName: "list.bullet",
                            playlistID: first.id,
                            thumbnailURL: thumbUrl
                        )
                    } else {
                        lastError = AppError.decodingError
                        break
                    }
                } catch {
                    lastError = error
                    continue
                }
            }
        }
        throw lastError
    }

    // Bequemlichkeits-Überladung: erlaubt Aufrufe ohne pageToken (lädt erste Seite)
    func fetchVideos(from playlistId: String, apiKey: String) async throws -> YouTubeResponse {
        try await fetchVideos(from: playlistId, apiKey: apiKey, pageToken: nil)
    }
    /// Löscht den in‑Memory‑Response‑Cache (z. B. bei Pull‑to‑Refresh/Force Reload)
    static func clearCache() {
        Task { await cache.clear() }
    }
}

// MARK: - Channels Response Models
struct YouTubeChannelListResponse: Decodable {
    let items: [YouTubeChannelItem]
}

struct YouTubeChannelItem: Decodable {
    let id: String
    let snippet: YouTubeChannelSnippet
    let statistics: YouTubeChannelStatistics?
}

struct YouTubeChannelSnippet: Decodable {
    let title: String
    let description: String
    let customUrl: String?
    let publishedAt: String?
    let thumbnails: YouTubeChannelThumbnails
}

struct YouTubeChannelThumbnails: Decodable {
    let high: YouTubeThumbImage?
    let medium: YouTubeThumbImage?
    let defaultThumb: YouTubeThumbImage?

    private enum CodingKeys: String, CodingKey {
        case high, medium
        case defaultThumb = "default"
    }
}

struct YouTubeThumbImage: Decodable {
    let url: String
    let width: Int?
    let height: Int?
}

struct YouTubeChannelStatistics: Decodable {
    let subscriberCount: String?
    let viewCount: String?
    let videoCount: String?
}
