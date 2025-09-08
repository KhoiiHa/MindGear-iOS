//
//  VideoViewModel.swift
//  MindGear_iOS
//
//  Zweck: UI‑Zustand & Logik für Playlist‑Videos inkl. Suche, Favorites & Paging.
//  Architekturrolle: ViewModel (MVVM).
//  Verantwortung: Initial‑Load (Remote‑Cache → API‑Fallback), Filter/Suche/Suggestions, Infinite Scroll.
//  Warum? Entkoppelt Views von Nebenwirkungen; deterministisches UI‑Binding & robuste Offline‑Strategien.
//  Testbarkeit: Services injizierbar (`APIServiceProtocol`), State via `@Published` prüfbar.
//  Status: stabil.
//
import Foundation
import SwiftData
// Kurzzusammenfassung: Erst Remote‑Cache, dann API; Suche mit Debounce; Favorites‑Sync; Paging mit Duplikat‑Schutz.

// MARK: - Implementierung: VideoViewModel
// Warum: Zentralisiert Playlist‑Video‑State; entlastet Views und hält UI konsistent.
@MainActor
class VideoViewModel: ObservableObject {
    // MARK: - State
    // Session‑Guard: Welche Playlists wurden in dieser App‑Session schon initial geladen?
    private static var loadedOnce = Set<String>()
    // UI‑Daten & Fehlerstatus
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

    /// Normalisiert Strings (diakritik‑insensitiv, case‑folded) für robuste Suche.
    /// Warum: Einheitliche Treffer auch bei ä/ö/ü und unterschiedlicher Groß‑/Kleinschreibung.
    private func norm(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current).lowercased()
    }

    /// Wendet die Suche auf `videos` an und aktualisiert `filteredVideos`.
    /// Warum: Trennung von State‑Mutation und UI‑Events; optionaler Favorites‑Filter.
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

    /// Leitet Playlist‑Metadaten defensiv aus vorhandenen Videos ab.
    /// Warum: UI‑Stabilität, bis echte Playlist‑Metadaten verfügbar sind.
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

    private var searchWorkItem: DispatchWorkItem?

    /// Debounce für die Suche (~250 ms), aus Views via `.onChange(of:)` oder Button‑Tap aufrufbar.
    /// Warum: Verhindert teure Filterung bei schnellem Tippen; Suggestions werden konsistent aktualisiert.
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
    /// Erzeugt Vorschlagstitel (max. `max`), priorisiert Präfix‑Treffer, diakritik‑insensitiv.
    /// Warum: Bessere UX bei der Suche; dedupliziert stabil.
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

    /// Wählt eine robuste Thumbnail‑URL und erzwingt HTTPS, Fallback auf `hqdefault`.
    /// Warum: Konsistente Bilddarstellung ohne Layout‑Sprünge.
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

    /// Mappt Remote‑JSON (GitHub Actions Cache) auf das App‑Modell `Video`.
    /// Warum: Schneller Erst‑Load; Favoriten werden gematcht und markiert.
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

    /// Lädt Videos für die Playlist (Remote‑Cache → API‑Fallback) und aktualisiert State.
    /// Warum: Schneller perceived Load über Remote; robuste Fehlerpfade inkl. Offline‑Favoriten.
    func loadVideos(forceReload: Bool = false) async {
        offlineMessage = nil
        errorMessage = nil // vorherige Fehlermeldung zurücksetzen
        // Reset Pagination-Status beim Initial-Load/Reload
        nextPageToken = nil
        hasMore = true
        loadMoreError = nil
        print("📡 loadVideos start for playlist", playlistId)
        // Session‑Guard: Initial‑Load pro Playlist nur einmal (sofern nicht erzwungen)
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

            // Fallback: Direkter API‑Pfad (PlaylistItems)
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
            case .invalidURL, .apiKeyMissing:
                errorMessage = "Ungültige oder fehlende API‑Konfiguration. Bitte Einstellungen prüfen."

            case .networkError, .timeout:
                if let underlying = error.errorDescription { print("Network error:", underlying) }
                let favorites = FavoritesManager.shared.getAllVideoFavorites(context: context)
                if favorites.isEmpty {
                    if errorMessage == nil || errorMessage?.isEmpty == true {
                        errorMessage = "Daten konnten nicht geladen werden. Bitte Verbindung prüfen und später erneut versuchen."
                    }
                } else {
                    errorMessage = nil
                    offlineMessage = "Offline‑Modus: Zeige gespeicherte Favoriten"
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

            case .httpStatus(let code):
                if code == 401 || code == 403 || code == 404 { // Unauthorized/Not found
                    errorMessage = "Zugriff nicht möglich (Status \(code)). Bitte später erneut versuchen."
                } else if code == 500 { // Serverfehler
                    errorMessage = "Serverfehler (500). Bitte später erneut versuchen."
                } else {
                    errorMessage = "Server‑Fehler (Status \(code))."
                }

            case .rateLimited(let retryAfter):
                if let s = retryAfter {
                    errorMessage = "Ratenlimit erreicht. Bitte in \(s) Sekunden erneut versuchen."
                } else {
                    errorMessage = "Ratenlimit erreicht. Bitte kurz warten und erneut versuchen."
                }

            case .decodingError, .invalidResponse, .noData:
                if let desc = (error as LocalizedError).errorDescription { print("Decoding/Response error:", desc) }
                if let apiErrorMessage = errorMessage, !apiErrorMessage.isEmpty {
                    errorMessage = apiErrorMessage
                } else {
                    errorMessage = "Fehler beim Verarbeiten der Daten. Versuche es später erneut."
                }

            case .unauthorized:
                errorMessage = "Zugriff nicht autorisiert. Bitte API‑Schlüssel/Anmeldung prüfen."

            case .unknown:
                errorMessage = "Ein unbekannter Fehler ist aufgetreten."

            case .underlying(let e):
                print("Underlying:", e.localizedDescription)
                errorMessage = e.localizedDescription
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

    /// Lädt weitere Videos (Infinite Scroll), wenn `nextPageToken` vorhanden ist.
    /// Warum: Verhindert Doppel‑Loads, dedupliziert per URL‑Set, hält Metadaten aktuell.
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
            // Weich fallen: Fehler mappen, dezente UI-Meldung, kein harter Abbruch
            let appErr = AppError.from(error)
            print("Mehr laden fehlgeschlagen:", appErr.localizedDescription)
            if appErr.isNetworkRelated && offlineMessage == nil {
                offlineMessage = "Netzwerkproblem – neuere Inhalte evtl. unvollständig."
            }
            self.loadMoreError = appErr.recoverySuggestion ?? appErr.errorDescription ?? "Konnte weitere Videos nicht laden."
        }
    }

    /// Wechselt den Favoritenstatus eines Videos und aktualisiert die Liste.
    /// Warum: Delegiert Persistenz an FavoritesManager; hält Filter/Suche konsistent.
    func toggleFavorite(for video: Video) async {
        await FavoritesManager.shared.toggleVideoFavorite(video: video, context: context)
        if let index = videos.firstIndex(of: video) {
            videos[index].isFavorite = FavoritesManager.shared.isVideoFavorite(video: video, context: context)
        }
        applySearch()
    }

    // UI‑Filter: Nur Favoriten anzeigen; triggert Re‑Filterung
    @Published var showFavoritesOnly: Bool = false { didSet { applySearch() } }

    /// Persistiert den Suchbegriff im Verlauf (max. 10, neuestes zuerst, ohne Duplikate).
    /// Warum: Bessere Wiederverwendbarkeit von Suchen; einfache UX.
    func commitSearchTerm() {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard term.count >= 2 else { return }
        var history = searchHistory.filter { $0.caseInsensitiveCompare(term) != .orderedSame }
        history.insert(term, at: 0)
        if history.count > 10 { history = Array(history.prefix(10)) }
        searchHistory = history
        UserDefaults.standard.set(history, forKey: searchHistoryKey)
    }

    /// Lädt gespeicherten Suchverlauf aus UserDefaults.
    private func loadSearchHistory() {
        if let arr = UserDefaults.standard.array(forKey: searchHistoryKey) as? [String] {
            searchHistory = arr
        }
    }

    /// Löscht den Suchverlauf (UI‑Action, z. B. Button).
    func clearSearchHistory() {
        searchHistory = []
        UserDefaults.standard.removeObject(forKey: searchHistoryKey)
    }
}
