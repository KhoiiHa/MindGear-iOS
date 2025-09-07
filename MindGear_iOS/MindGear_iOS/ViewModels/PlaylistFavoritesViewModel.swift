
//
//  PlaylistFavoritesViewModel.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 11.08.25.
//

import Foundation
import SwiftData

/// ViewModel für das Verwalten von favorisierten **Playlists**.
/// Nutzt `FavoritePlaylistEntity` (SwiftData) und den `FavoritesManager`.
/// Zeigt Favoritenliste für Playlists im Tab "Favoriten".
@MainActor
final class PlaylistFavoritesViewModel: ObservableObject {
    // MARK: - State
    @Published var favoritePlaylists: [FavoritePlaylistEntity] = []

    private let context: ModelContext

    // MARK: - Init
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Loading
    /// Lädt alle Playlist-Favoriten (neueste zuerst)
    func reload() {
        let desc = FetchDescriptor<FavoritePlaylistEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            favoritePlaylists = try context.fetch(desc)
        } catch {
            print("Failed to fetch playlist favorites:", error)
            favoritePlaylists = []
        }
    }

    // MARK: - Queries
    /// Prüft, ob eine Playlist bereits favorisiert ist
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
    /// Toggle – setzt oder entfernt den Favoritenstatus
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
    /// Entfernt explizit einen Favoriten nach ID
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

