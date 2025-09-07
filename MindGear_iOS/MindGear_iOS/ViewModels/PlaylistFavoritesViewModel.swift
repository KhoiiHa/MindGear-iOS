//
//  PlaylistFavoritesViewModel.swift
//  MindGear_iOS
//
//  Zweck: UI‑Zustand & Logik für favorisierte Playlists.
//  Architekturrolle: ViewModel (MVVM).
//  Verantwortung: Laden/Sortieren, Toggle‑Intents, explizites Entfernen.
//  Warum? Entkoppelt Views von Persistenz; konsistente Liste & deterministische Tests.
//  Testbarkeit: SwiftData‑Context injizierbar; State & Queries einfach prüfbar.
//  Status: stabil.
//

import Foundation
import SwiftData
// Kurzzusammenfassung: Holt Favoriten (neueste zuerst), prüft Status und toggelt/entfernt per FavoritesManager.

// MARK: - Implementierung: PlaylistFavoritesViewModel
// Warum: Zentralisiert Playlist‑Favoriten; erleichtert UI‑Tests & Wiederverwendung.
@MainActor
final class PlaylistFavoritesViewModel: ObservableObject {
    // MARK: - State
    @Published var favoritePlaylists: [FavoritePlaylistEntity] = []

    // Injektionspunkt für SwiftData – erleichtert Tests & Previews
    private let context: ModelContext

    // MARK: - Init
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Loading
    /// Lädt alle Playlist‑Favoriten (neueste zuerst).
    /// Warum: Konsistente Anzeige & deterministische UI‑Tests.
    func reload() {
        let desc = FetchDescriptor<FavoritePlaylistEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            // Neueste zuerst – erleichtert Wahrnehmung & Teststabilität
            favoritePlaylists = try context.fetch(desc)
        } catch {
            print("Failed to fetch playlist favorites:", error)
            favoritePlaylists = []
        }
    }

    // MARK: - Queries
    /// Prüft, ob eine Playlist bereits favorisiert ist.
    /// Warum: Schneller Lookup für Toggle/Buttons in der UI.
    func isFavorite(id playlistId: String) -> Bool {
        do {
            let desc = FetchDescriptor<FavoritePlaylistEntity>(
                predicate: #Predicate { $0.id == playlistId }
            )
            return try !context.fetch(desc).isEmpty
        } catch {
            print("Failed to check playlist favorite:", error)
            return false
        }
    }

    // MARK: - Mutations
    /// Schaltet den Favoritenstatus einer Playlist um.
    /// Warum: Delegiert Persistenz an FavoritesManager; `reload()` hält UI state‑aktuell.
    func toggleFavorite(id playlistId: String, title: String, thumbnailURL: String) async {
        await FavoritesManager.shared.togglePlaylistFavorite(
            id: playlistId,
            title: title,
            thumbnailURL: thumbnailURL,
            context: context
        )
        reload()
    }

    // MARK: - Deletion
    /// Entfernt explizit einen Playlist‑Favoriten anhand der ID.
    /// Warum: Bietet direkten Lösch‑Flow (z. B. Swipe‑to‑Delete) und aktualisiert die Liste.
    func removeFavorite(id playlistId: String) {
        do {
            let desc = FetchDescriptor<FavoritePlaylistEntity>(
                predicate: #Predicate { $0.id == playlistId }
            )
            if let entity = try context.fetch(desc).first {
                context.delete(entity)
                try? context.save()
                reload()
            }
        } catch {
            print("Failed to remove playlist favorite:", error)
        }
    }
}
