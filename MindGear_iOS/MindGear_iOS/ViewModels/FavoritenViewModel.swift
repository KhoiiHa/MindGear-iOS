//
//  FavoritenViewModel.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 07.07.25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class FavoritenViewModel: ObservableObject {

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

    @Published var allFavorites: [FavoriteItem] = []

    let context: ModelContext
    private var favoritesObserver: NSObjectProtocol?

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

    func loadFavorites() {
        let videoFavorites = FavoritesManager.shared.getAllVideoFavorites(context: context).map {
            FavoriteItem(
                id: String(describing: $0.id),
                type: .video,
                title: $0.title,
                thumbnailURL: $0.thumbnailURL,
                dateAdded: $0.createdAt
            )
        }
        let mentorFavorites = FavoritesManager.shared.getAllMentorFavorites(context: context).map {
            FavoriteItem(
                id: String(describing: $0.id),
                type: .mentor,
                title: $0.name,
                thumbnailURL: $0.profileImageURL,
                dateAdded: $0.createdAt
            )
        }
        let playlistFavorites = FavoritesManager.shared.getAllPlaylistFavorites(context: context).map {
            FavoriteItem(
                id: String(describing: $0.id),
                type: .playlist,
                title: $0.title,
                thumbnailURL: $0.thumbnailURL,
                dateAdded: $0.createdAt
            )
        }
        let combined = videoFavorites + mentorFavorites + playlistFavorites
        allFavorites = combined.sorted(by: { $0.dateAdded > $1.dateAdded })
    }

    func toggleFavorite(video: Video) async {
        await FavoritesManager.shared.toggleVideoFavorite(video: video, context: context)
        loadFavorites()
    }

    func toggleFavorite(mentor: Mentor) async {
        await FavoritesManager.shared.toggleMentorFavorite(mentor: mentor, context: context)
        loadFavorites()
    }

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

    func isFavorite(video: Video) -> Bool {
        let result = FavoritesManager.shared.isVideoFavorite(video: video, context: context)
        loadFavorites()
        return result
    }

    func isFavorite(mentor: Mentor) -> Bool {
        let result = FavoritesManager.shared.isMentorFavorite(mentor: mentor, context: context)
        loadFavorites()
        return result
    }

    /// Prüft, ob eine Playlist bereits favorisiert ist.
    func isPlaylistFavorite(id playlistId: String) -> Bool {
        let result = FavoritesManager.shared.isPlaylistFavorite(id: playlistId, context: context)
        loadFavorites()
        return result
    }

    deinit {
        if let observer = favoritesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
