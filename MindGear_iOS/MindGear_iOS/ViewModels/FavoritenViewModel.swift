//
//  FavoritenViewModel.swift
//  MindGear_iOS
//
//  Zweck: UI‑Zustand & Logik für die Favoriten‑Übersicht (Videos, Mentoren, Playlists).
//  Architekturrolle: ViewModel (MVVM).
//  Verantwortung: Laden/Sortieren, Toggle‑Intents, Live‑Updates via Notification.
//  Warum? Entkoppelt Views von Persistenz‑/Service‑Details; deterministisches UI‑Binding.
//  Testbarkeit: SwiftData‑Context injizierbar; Notifications und State leicht zu verifizieren.
//  Status: stabil.
//

import Foundation
import SwiftData
import SwiftUI
// Kurzzusammenfassung: Aggregiert Favoriten aus SwiftData, hört auf Änderungen und bietet Toggle/Queries für die UI.

// MARK: - Implementierung: FavoritenViewModel
// Warum: Zentralisiert Favoriten‑State; erleichtert UI‑Tests & Wiederverwendung.
@MainActor
class FavoritenViewModel: ObservableObject {

    // MARK: - Types
    enum FavoriteType {
        case video
        case mentor
        case playlist
    }

    struct FavoriteItem: Identifiable {
        let id: String
        let type: FavoriteType
        let title: String
        let thumbnailURL: String?
        let dateAdded: Date
    }

    // MARK: - State
    // ⚠️ UI-Test IDs: favoritesSearchField, favoritesList, favoritesDeleteButton (siehe Tests)
    @Published var allFavorites: [FavoriteItem] = []
    // Injektionspunkt für SwiftData – erleichtert Tests & Previews
    let context: ModelContext
    // Hält Notification-Token für Live-Updates (Thread-sicher via @MainActor)
    private var favoritesObserver: NSObjectProtocol?

    // MARK: - Init
    init(context: ModelContext) {
        self.context = context
        // Initial-Ladung für sofortige UI (deterministische Startliste)
        loadFavorites()
        // Live-Updates: reagiert auf .favoritesDidChange und lädt sortiert neu
        favoritesObserver = NotificationCenter.default.addObserver(forName: .favoritesDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.loadFavorites()
            }
        }
    }

    /// Lädt alle Favoriten (Video, Mentor, Playlist) und sortiert absteigend nach Datum.
    /// Warum: Konsistente Anzeige & deterministische UI‑Tests (Liste → `favoritesList`).
    func loadFavorites() {
        let videoFavorites = FavoritesManager.shared.getAllVideoFavorites(context: context).map {
            FavoriteItem(
                id: $0.videoURL,
                type: .video,
                title: $0.title,
                thumbnailURL: $0.thumbnailURL,
                dateAdded: $0.createdAt
            )
        }
        let mentorFavorites = FavoritesManager.shared.getAllMentorFavorites(context: context).map {
            FavoriteItem(
                id: $0.id, // Channel-ID des Mentors als eindeutige ID
                type: .mentor,
                title: $0.name,
                thumbnailURL: $0.profileImageURL,
                dateAdded: $0.createdAt
            )
        }
        let playlistFavorites = FavoritesManager.shared.getAllPlaylistFavorites(context: context).map {
            FavoriteItem(
                id: $0.id,
                type: .playlist,
                title: $0.title,
                thumbnailURL: $0.thumbnailURL,
                dateAdded: $0.createdAt
            )
        }
        let combined = videoFavorites + mentorFavorites + playlistFavorites
        // Neueste zuerst – erleichtert Wahrnehmung & Teststabilität
        allFavorites = combined.sorted(by: { $0.dateAdded > $1.dateAdded })
    }

    // MARK: - Actions (Toggle)

    /// Schaltet den Favoritenstatus eines Videos um.
    /// Warum: Delegiert Persistenz an FavoritesManager und hält UI state‑aktuell.
    func toggleFavorite(video: Video) async {
        await FavoritesManager.shared.toggleVideoFavorite(video: video, context: context)
        loadFavorites()
    }

    /// Schaltet den Favoritenstatus eines Mentors um.
    /// Warum: Delegiert Persistenz an FavoritesManager und hält UI state‑aktuell.
    func toggleFavorite(mentor: Mentor) async {
        await FavoritesManager.shared.toggleMentorFavorite(mentor: mentor, context: context)
        loadFavorites()
    }

    /// Schaltet den Favoritenstatus einer Playlist um.
    /// Warum: Delegiert Persistenz an FavoritesManager; UI erhält aktualisierte Liste.
    /// Verwende `playlistId`, `title` und `thumbnailURL` aus deiner View / deinem ViewModel.
    func togglePlaylistFavorite(id playlistId: String, title: String, thumbnailURL: String) async {
        await FavoritesManager.shared.togglePlaylistFavorite(
            id: playlistId,
            title: title,
            thumbnailURL: thumbnailURL,
            context: context
        )
        loadFavorites()
    }

    // MARK: - Queries (Read‑Only)

    /// Warum: Schneller Lookup für Bindings/Buttons in der UI.
    func isFavorite(video: Video) -> Bool {
        FavoritesManager.shared.isVideoFavorite(video: video, context: context)
    }

    /// Warum: Schneller Lookup für Bindings/Buttons in der UI.
    func isFavorite(mentor: Mentor) -> Bool {
        FavoritesManager.shared.isMentorFavorite(mentor: mentor, context: context)
    }

    /// Warum: Schneller Lookup für Bindings/Buttons in der UI.
    /// Prüft, ob eine Playlist bereits favorisiert ist.
    func isPlaylistFavorite(id playlistId: String) -> Bool {
        FavoritesManager.shared.isPlaylistFavorite(id: playlistId, context: context)
    }

    // MARK: - Deinit
    deinit {
        if let observer = favoritesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
