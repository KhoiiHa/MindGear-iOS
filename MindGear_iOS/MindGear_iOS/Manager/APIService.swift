import Foundation

// YouTube-Fehlerhülle zum Dekodieren von Fehlerantworten
struct YouTubeAPIErrorEnvelope: Decodable, Error {
    struct Inner: Decodable { let code: Int; let message: String }
    let error: Inner
}

protocol APIServiceProtocol {
    /// Lädt YouTube-PlaylistItems. Optionaler pageToken ermöglicht Pagination.
    func fetchVideos(from playlistId: String, apiKey: String, pageToken: String?) async throws -> YouTubeResponse
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
        let cfg = URLSessionConfiguration.default
        cfg.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Accept-Encoding": "gzip, deflate, br",
            "User-Agent": "MindGear-iOS/1.0"
        ]
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
                request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")

                print("🔎 URL:", url.absoluteString)
                let (data, response) = try await APIService.session.data(for: request)

                if let http = response as? HTTPURLResponse {
                    print("🌐 STATUS:", http.statusCode)
                    print("🌐 HEADERS:", http.allHeaderFields)
                }

                // HTML erkennen (Zustimmungs-/Blockierungsseiten)
                if let text = String(data: data.prefix(200), encoding: .utf8),
                   text.contains("<html") || text.contains("<!DOCTYPE html") {
                    let preview = String(data: data.prefix(400), encoding: .utf8) ?? "<non-utf8>"
                    print("❗️HTML statt JSON. KÖRPER-Vorschau:\n\(preview)")
                    lastError = AppError.networkError
                    continue // nächsten Host versuchen
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
                    continue // nächsten Host versuchen
                }

                // Erfolgreicher Pfad: Elemente dekodieren
                do {
                    let response = try JSONDecoder().decode(YouTubeResponse.self, from: data)
                    return response
                } catch {
                    let preview = String(data: data.prefix(400), encoding: .utf8) ?? "<non-utf8>"
                    print("❗️Dekodierung fehlgeschlagen. KÖRPER-Vorschau:\n\(preview)")
                    lastError = AppError.decodingError
                    continue // nächsten Host versuchen
                }
            } catch {
                print("❗️Transportfehler:", error.localizedDescription)
                lastError = error
                continue // nächsten Host versuchen
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

    // Bequemlichkeits-Überladung: erlaubt Aufrufe ohne pageToken (lädt erste Seite)
    func fetchVideos(from playlistId: String, apiKey: String) async throws -> YouTubeResponse {
        try await fetchVideos(from: playlistId, apiKey: apiKey, pageToken: nil)
    }
}
