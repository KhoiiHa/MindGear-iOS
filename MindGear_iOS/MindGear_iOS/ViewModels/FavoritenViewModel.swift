//
//  FavoritenViewModel.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 07.07.25.
//

import Foundation
import SwiftData

class FavoritenViewModel: ObservableObject {
    @Published var favorites: [FavoriteVideoEntity] = []

    init(context: ModelContext) {
        loadFavorites(context: context)
    }

    func loadFavorites(context: ModelContext) {
        favorites = FavoritesManager.shared.getAllFavorites(context: context)
    }

    func toggleFavorite(video: Video, context: ModelContext) {
        FavoritesManager.shared.toggleFavorite(video: video, context: context)
        loadFavorites(context: context)
    }

    func isFavorite(video: Video, context: ModelContext) -> Bool {
        FavoritesManager.shared.isFavorite(video: video, context: context)
    }
}
