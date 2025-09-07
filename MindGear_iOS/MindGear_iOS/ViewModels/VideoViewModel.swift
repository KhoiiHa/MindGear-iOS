import Foundation
import SwiftData

// Steuert Videos einer Playlist inkl. Suche, Paging und Offline-Fallback
@MainActor
class VideoViewModel: ObservableObject {
    // MARK: - State
    // Merker: Welche Playlists wurden in dieser App-Session bereits einmal initial geladen?
    private static var loadedOnce = Set<String>()
    @Published var videos: [Video] = []
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""
    @Published var filteredVideos: [Video] = []
    // Autovervollständigung & Verlauf
    @Published var suggestions: [String] = []
    @Published var searchHistory: [String] = []
    private let searchHistoryKey = "SearchHistory.v1"
    /// Metadaten der aktuellen Playlist (für Favoriten-Button etc.)
    @Published var playlistTitle: String = ""
    @Published var playlistThumbnailURL: String = ""
    private var searchTask: Task<Void, Never>? = nil

    /// Normalisiert Strings (diakritik-insensitiv, lowercase) für eine robuste Suche
    private func norm(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current).lowercased()
    }

    /// Wendet die Suche auf `videos` an und aktualisiert `filteredVideos`
    private func applySearch() {
        let q = norm(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
        let base = videos
        let filteredByQuery: [Video]
        if q.isEmpty {
            filteredByQuery = base
        } else {
            filteredByQuery = base.filter { v in
                let title = norm(v.title)
                let desc  = norm(v.description)
                let cat   = norm(v.category)
                return title.contains(q) || desc.contains(q) || cat.contains(q)
            }
        }
        if showFavoritesOnly {
            filteredVideos = filteredByQuery.filter { $0.isFavorite }
        } else {
            filteredVideos = filteredByQuery
        }
    }

    /// Leitet Playlist-Metadaten aus der ersten Videokarte ab (Fallback, bis echte Playlist-API genutzt wird).
    /// Setzt nur dann Default-Werte, wenn gar keine Videos vorhanden sind.
    private func updatePlaylistMetaFromVideosIfNeeded() {
        if let first = videos.first {
            if playlistTitle.isEmpty { playlistTitle = first.title }
            if playlistThumbnailURL.isEmpty { playlistThumbnailURL = first.thumbnailURL }
        } else {
            // Defensive Defaults (UI bleibt stabil, ohne Annahmen über Assets)
            if playlistTitle.isEmpty { playlistTitle = "Unbekannte Playlist" }
            // Thumbnail leer lassen, damit UI einen Platzhalter anzeigen kann
            if playlistThumbnailURL.isEmpty { playlistThumbnailURL = "" }
        }
    }

    
    /// Debounce für die Suchanfrage (~250 ms), ohne Combine-Overhead.
    /// Wird direkt aus der View via `.onChange(of:)` oder Button-Tap aufgerufen.
    private var searchWorkItem: DispatchWorkItem?

    func updateSearch(text: String) {
        searchText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        searchWorkItem?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.applySearch()
            self.suggestions = Self.makeSuggestions(from: self.filteredVideos, query: self.searchText)
        }
        searchWorkItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: task)
    }
    @Published var offlineMessage: String? = nil

    // Pagination-Status
    @Published var isLoadingMore: Bool = false
    private var nextPageToken: String? = nil
    @Published var hasMore: Bool = true
    @Published var loadMoreError: String? = nil

    // Lädt API-Schlüssel dynamisch aus der Config
    private let apiKey = ConfigManager.youtubeAPIKey
    private let playlistId: String

    private let apiService: APIServiceProtocol
    private var context: ModelContext

    init(playlistId: String, apiService: APIServiceProtocol = APIService.shared, context: ModelContext) {
        self.playlistId = playlistId
        self.apiService = apiService
        self.context = context
        self.loadSearchHistory()
    }
    /// Erzeugt Vorschlagstitel (max 6), priorisiert Präfix-Treffer, diakritik-insensitiv.
    static func makeSuggestions(from videos: [Video], query: String, max: Int = 6) -> [String] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = q.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        guard normalized.count >= 2 else { return [] }
        let titles = videos.map { $0.title }
        let prefix = titles.filter { $0.folding(options: .diacriticInsensitive, locale: .current).lowercased().hasPrefix(normalized) }
        let rest = titles.filter { title in
            let t = title.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            return t.contains(normalized) && !t.hasPrefix(normalized)
        }
        var merged: [String] = []
        for t in (prefix + rest) {
            if !merged.contains(t) { merged.append(t) }
        }
        return Array(merged.prefix(max))
    }

    /// Wählt eine robuste Thumbnail-URL und erzwingt HTTPS.
    /// Reihenfolge: maxres → standard → high → medium → default; Fallback auf hqdefault.
    private func makeThumbnailURL(from thumbnails: Thumbnails?, videoID: String) -> String {
        // Kandidaten aus der API, in sinnvoller Reihenfolge
        let candidates: [String?] = [
            thumbnails?.maxres?.url,
            thumbnails?.standard?.url,
            thumbnails?.high?.url,
            thumbnails?.medium?.url,
            thumbnails?.defaultThumbnail?.url
        ]
        // Erste nicht-leere URL wählen
        var url = candidates.compactMap { $0 }.first ?? ""
        // HTTPS erzwingen
        if url.hasPrefix("http://") { url = url.replacingOccurrences(of: "http://", with: "https://") }
        // Fallback: stabile YouTube-hqdefault, falls keine API-URL vorhanden
        if url.isEmpty {
            url = "https://i.ytimg.com/vi/\(videoID)/hqdefault.jpg"
        }
        return url
    }

    // Mappt Remote-JSON (GitHub Actions Cache) -> bestehendes Video-Modell
    private func mapFromRemote(_ remote: RemoteVideosCache) -> [Video] {
        let favorites = FavoritesManager.shared.getAllVideoFavorites(context: context)
        return remote.videos.compactMap { item in
            guard let id = item.id else { return nil }
            let thumb = item.thumbnails?.high ?? item.thumbnails?.medium ?? item.thumbnails?.`default` ?? "https://i.ytimg.com/vi/\(id)/hqdefault.jpg"
            var video = Video(
                id: UUID(),
                title: item.title,
                description: item.description,
                thumbnailURL: thumb.hasPrefix("http://") ? thumb.replacingOccurrences(of: "http://", with: "https://") : thumb,
                videoURL: id, // wir speichern nur die reine Video-ID
                category: "YouTube"
            )
            if favorites.contains(where: { $0.videoURL == id }) {
                video.isFavorite = true
            }
            return video
        }
    }

    /// Lädt Videos aus der YouTube-Playlist und aktualisiert die Liste der Videos.
    /// Behandelt Fehler und zeigt gegebenenfalls Favoriten im Offline-Modus an.
    func loadVideos(forceReload: Bool = false) async {
        offlineMessage = nil
        errorMessage = nil // vorherige Fehlermeldung zurücksetzen
        // Reset Pagination-Status beim Initial-Load/Reload
        nextPageToken = nil
        hasMore = true
        loadMoreError = nil
        print("📡 loadVideos start for playlist", playlistId)
        // Session-Guard: dieselbe Playlist nicht mehrfach initial laden (sofern nicht erzwungen)
        if !forceReload, Self.loadedOnce.contains(playlistId), !videos.isEmpty {
            print("🧠 Session-Guard: Initial-Load für \(playlistId) übersprungen (bereits geladen in dieser Session)")
            return
        }
        do {
            // 1) Schnellweg: Remote-JSON aus /data (GitHub Actions)
            do {
                let remote = try await RemoteCacheService.loadVideos(playlistId: playlistId)
                let mapped = mapFromRemote(remote)
                if !mapped.isEmpty {
                    self.videos = mapped
                    // Remote enthält bereits die komplette Liste -> keine Pagination
                    self.nextPageToken = nil
                    self.hasMore = false
                    updatePlaylistMetaFromVideosIfNeeded()
                    Self.loadedOnce.insert(self.playlistId)
                    applySearch()
                    print("✅ Remote JSON ok · items:\(mapped.count)")
                    return
                }
            } catch {
                print("ℹ️ Remote JSON nicht verfügbar → Fallback API: \(error.localizedDescription)")
            }

            // 2) Fallback: bisheriger Pfad über YouTube API
            let response = try await apiService.fetchVideos(from: playlistId, apiKey: apiKey, pageToken: nil)
            let items = response.items
            self.nextPageToken = response.nextPageToken
            self.hasMore = (response.nextPageToken != nil) && !items.isEmpty
            print("✅ API ok · items:\(items.count) · nextToken:\(self.nextPageToken ?? "nil")")
            let favorites = FavoritesManager.shared.getAllVideoFavorites(context: context)
            self.videos = items.compactMap { item -> Video? in
                guard
                    let snippet = item.snippet,
                    let videoId = snippet.resourceId?.videoId,
                    let title = snippet.title,
                    let description = snippet.description
                else {
                    return nil
                }
                let cleanID = Video.extractVideoID(from: videoId)
                let url = cleanID
                let thumbnailURL = makeThumbnailURL(from: snippet.thumbnails, videoID: cleanID)
                var video = Video(
                    id: UUID(),
                    title: title,
                    description: description,
                    thumbnailURL: thumbnailURL,
                    videoURL: url,
                    category: "YouTube"
                )
                if favorites.contains(where: { $0.videoURL == url }) {
                    video.isFavorite = true
                }
                return video
            }
            updatePlaylistMetaFromVideosIfNeeded()
            Self.loadedOnce.insert(self.playlistId)
            applySearch()
        } catch let error as AppError {
            switch error {
            case .invalidURL:
                errorMessage = "Ungültige URL. Bitte überprüfe die API-Einstellungen."
            case .networkError:
                if let underlying = error.errorDescription {
                    print("Network error occurred:", underlying)
                }
                let favorites = FavoritesManager.shared.getAllVideoFavorites(context: context)
                if favorites.isEmpty {
                    if errorMessage == nil || errorMessage?.isEmpty == true {
                        errorMessage = "Daten konnten nicht geladen werden. Bitte Verbindung prüfen und später erneut versuchen."
                    }
                } else {
                    errorMessage = nil
                    offlineMessage = "Offline-Modus: Zeige gespeicherte Favoriten"
                    self.videos = favorites.map { fav in
                        Video(
                            id: fav.id,
                            title: fav.title,
                            description: fav.videoDescription,
                            thumbnailURL: fav.thumbnailURL,
                            videoURL: fav.videoURL,
                            category: fav.category,
                            isFavorite: true
                        )
                    }
                    applySearch()
                    self.hasMore = false
                    self.nextPageToken = nil
                }
            case .decodingError:
                if let underlyingError = (error as LocalizedError).errorDescription {
                    print("Decoding error occurred: \(underlyingError)")
                }
                if let apiErrorMessage = errorMessage, !apiErrorMessage.isEmpty {
                    errorMessage = apiErrorMessage
                } else {
                    errorMessage = "Fehler beim Verarbeiten der Daten. Versuche es später erneut."
                }
            case .unknown:
                errorMessage = "Ein unbekannter Fehler ist aufgetreten."
            }
        } catch {
            if let urlErr = error as? URLError {
                print("🌐 URLError:", urlErr.code, urlErr.localizedDescription)
                let favorites = FavoritesManager.shared.getAllVideoFavorites(context: context)
                if favorites.isEmpty {
                    switch urlErr.code {
                    case .notConnectedToInternet, .timedOut, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost:
                        errorMessage = "Netzwerkverbindung verloren. Bitte versuche es erneut."
                    case .cannotParseResponse, .badServerResponse:
                        print("⚠️ Serverantwort nicht parsebar / ungültig (\(urlErr.code.rawValue)):", urlErr.localizedDescription)
                        errorMessage = "Daten konnten nicht geladen werden. Der Server lieferte keine gültigen Informationen. Bitte später erneut versuchen."
                    default:
                        errorMessage = "Netzwerkfehler. Bitte versuche es erneut."
                    }
                } else {
                    errorMessage = nil
                    offlineMessage = "Offline-Modus: Zeige gespeicherte Favoriten"
                    self.videos = favorites.map { fav in
                        Video(
                            id: fav.id,
                            title: fav.title,
                            description: fav.videoDescription,
                            thumbnailURL: fav.thumbnailURL,
                            videoURL: fav.videoURL,
                            category: fav.category,
                            isFavorite: true
                        )
                    }
                    applySearch()
                    self.hasMore = false
                    self.nextPageToken = nil
                }
            } else {
                print("❗️Unexpected error:", error.localizedDescription)
                errorMessage = "Ein unerwarteter Fehler ist aufgetreten."
            }
        }
    }

    /// Lädt weitere Videos, falls ein nextPageToken vorhanden ist (Infinite Scroll)
    func loadMoreVideos() async {
        guard !isLoadingMore, hasMore, let token = nextPageToken, !token.isEmpty else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            loadMoreError = nil
            let response = try await apiService.fetchVideos(from: playlistId, apiKey: apiKey, pageToken: token)
            let favorites = FavoritesManager.shared.getAllVideoFavorites(context: context)
            let newVideos: [Video] = response.items.compactMap { item -> Video? in
                guard
                    let snippet = item.snippet,
                    let videoId = snippet.resourceId?.videoId,
                    let title = snippet.title,
                    let description = snippet.description
                else { return nil }

                // Video-ID Normalisierung: Nur reine Video-ID speichern
                let cleanID = Video.extractVideoID(from: videoId)
                let url = cleanID

                let thumbnailURL = makeThumbnailURL(from: snippet.thumbnails, videoID: cleanID)

                var video = Video(
                    id: UUID(),
                    title: title,
                    description: description,
                    thumbnailURL: thumbnailURL,
                    videoURL: url,
                    category: "YouTube"
                )
                if favorites.contains(where: { $0.videoURL == url }) {
                    video.isFavorite = true
                }
                return video
            }
            // Duplikate vermeiden: existierende Video-URLs sammeln und nur neue anhängen
            let existingURLs = Set(self.videos.map { $0.videoURL })
            let uniqueNewVideos = newVideos.filter { !existingURLs.contains($0.videoURL) }
            self.videos.append(contentsOf: uniqueNewVideos)
            // Falls noch keine Metadaten gesetzt sind, jetzt aus vorhandenen Videos ableiten
            if playlistTitle.isEmpty || playlistThumbnailURL.isEmpty {
                updatePlaylistMetaFromVideosIfNeeded()
            }
            applySearch()
            // Token & Flag für die nächste Seite aktualisieren
            self.nextPageToken = response.nextPageToken
            self.hasMore = (response.nextPageToken != nil) && !response.items.isEmpty
        } catch {
            // Kein hartes UI-Feedback nötig; Log genügt für Debugging
            print("Mehr laden fehlgeschlagen:", error.localizedDescription)
            self.loadMoreError = error.localizedDescription
        }
    }

    /// Wechselt den Favoritenstatus eines Videos und aktualisiert die Ansicht entsprechend.
    func toggleFavorite(for video: Video) async {
        await FavoritesManager.shared.toggleVideoFavorite(video: video, context: context)
        if let index = videos.firstIndex(of: video) {
            videos[index].isFavorite = FavoritesManager.shared.isVideoFavorite(video: video, context: context)
        }
        applySearch()
    }

    @Published var showFavoritesOnly: Bool = false { didSet { applySearch() } }

    /// Speichert den aktuellen Suchbegriff im Verlauf (max. 10 Einträge, neuestes zuerst, ohne Duplikate)
    func commitSearchTerm() {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard term.count >= 2 else { return }
        var history = searchHistory.filter { $0.caseInsensitiveCompare(term) != .orderedSame }
        history.insert(term, at: 0)
        if history.count > 10 { history = Array(history.prefix(10)) }
        searchHistory = history
        UserDefaults.standard.set(history, forKey: searchHistoryKey)
    }

    /// Lädt den gespeicherten Suchverlauf aus UserDefaults
    private func loadSearchHistory() {
        if let arr = UserDefaults.standard.array(forKey: searchHistoryKey) as? [String] {
            searchHistory = arr
        }
    }

    /// Löscht den Suchverlauf (UI kann diese Funktion z. B. über einen Button anstoßen)
    func clearSearchHistory() {
        searchHistory = []
        UserDefaults.standard.removeObject(forKey: searchHistoryKey)
    }
}
