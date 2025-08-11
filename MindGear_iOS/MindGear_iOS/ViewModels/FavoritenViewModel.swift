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
    @Published var favorites: [FavoriteVideoEntity] = []
    @Published var favoriteMentors: [FavoriteMentorEntity] = []
    @Published var favoritePlaylists: [FavoritePlaylistEntity] = []

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
        favorites = FavoritesManager.shared.getAllVideoFavorites(context: context)
        favoriteMentors = FavoritesManager.shared.getAllMentorFavorites(context: context)
        favoritePlaylists = FavoritesManager.shared.getAllPlaylistFavorites(context: context)
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
        FavoritesManager.shared.isVideoFavorite(video: video, context: context)
    }

    func isFavorite(mentor: Mentor) -> Bool {
        FavoritesManager.shared.isMentorFavorite(mentor: mentor, context: context)
    }

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
