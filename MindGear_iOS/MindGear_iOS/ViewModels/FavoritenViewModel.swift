//
//  FavoritenViewModel.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 07.07.25.
//

import Foundation
import SwiftData
import SwiftUI

/// Bündelt Video-, Mentor- und Playlist-Favoriten für die UI
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
    @Published var allFavorites: [FavoriteItem] = []
    // ⚠️ UI-Test IDs: favoritesSearchField, favoritesList, favoritesDeleteButton

    let context: ModelContext
    private var favoritesObserver: NSObjectProtocol?

    // MARK: - Init / Deinit
    init(context: ModelContext) {
        self.context = context
        // Initial laden
        loadFavorites()
        // Live-Updates beobachten (Thread-sicher via MainActor)
        favoritesObserver = NotificationCenter.default.addObserver(forName: .favoritesDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.loadFavorites()
            }
        }
    }

    // Lädt alle Favoriten aus Video, Mentor und Playlist, sortiert nach Datum – wichtig für UI-Tests (Liste → favoritesList).
    // MARK: - Loading
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
        allFavorites = combined.sorted(by: { $0.dateAdded > $1.dateAdded })
    }

    // UI-Test: Favorit-Status eines Videos ändern (Button-ID: favoriteButton).
    // MARK: - Mutations (toggle)
    func toggleFavorite(video: Video) async {
        await FavoritesManager.shared.toggleVideoFavorite(video: video, context: context)
        loadFavorites()
    }

    // UI-Test: Favorit-Status eines Mentors ändern.
    func toggleFavorite(mentor: Mentor) async {
        await FavoritesManager.shared.toggleMentorFavorite(mentor: mentor, context: context)
        loadFavorites()
    }

    // UI-Test: Favorit-Status einer Playlist ändern.
    /// Schaltet den Favoritenstatus einer Playlist um.
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

    // Prüfen ob Video als Favorit markiert ist.
    // MARK: - Queries (read-only)
    func isFavorite(video: Video) -> Bool {
        FavoritesManager.shared.isVideoFavorite(video: video, context: context)
    }

    // Prüfen ob Mentor als Favorit markiert ist.
    func isFavorite(mentor: Mentor) -> Bool {
        FavoritesManager.shared.isMentorFavorite(mentor: mentor, context: context)
    }

    // Prüfen ob Playlist als Favorit markiert ist.
    /// Prüft, ob eine Playlist bereits favorisiert ist.
    func isPlaylistFavorite(id playlistId: String) -> Bool {
        FavoritesManager.shared.isPlaylistFavorite(id: playlistId, context: context)
    }

    deinit {
        if let observer = favoritesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
