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

    @Environment(\.modelContext) private var context

    init() {
        loadFavorites()
    }

    func loadFavorites() {
        favorites = FavoritesManager.shared.getAllFavorites(context: context)
    }

    func toggleFavorite(video: Video) async {
        await FavoritesManager.shared.toggleFavorite(video: video, context: context)
        loadFavorites()
    }

    func isFavorite(video: Video) -> Bool {
        FavoritesManager.shared.isFavorite(video: video, context: context)
    }
}
