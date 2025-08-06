//
//  FavoritenViewModel.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 07.07.25.
//

import Foundation
import SwiftData
import SwiftUI

class FavoritenViewModel: ObservableObject {
    @Published var favorites: [FavoriteVideoEntity] = []

    var context: ModelContext?

    init(context: ModelContext? = nil) {
        self.context = context
        if let context = context {
            loadFavorites(context: context)
        }
    }

    func loadFavorites(context: ModelContext? = nil) {
        guard let ctx = context ?? self.context else { return }
        favorites = FavoritesManager.shared.getAllFavorites(context: ctx)
    }

    func toggleFavorite(video: Video) async {
        guard let ctx = context else { return }
        await FavoritesManager.shared.toggleFavorite(video: video, context: ctx)
        loadFavorites(context: ctx)
    }

    func isFavorite(video: Video) -> Bool {
        guard let ctx = context else { return false }
        return FavoritesManager.shared.isFavorite(video: video, context: ctx)
    }
}
