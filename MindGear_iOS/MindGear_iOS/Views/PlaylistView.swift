//
//  PlaylistView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 29.07.25.
//

import SwiftUI
import SwiftData

struct PlaylistView: View {
    @StateObject private var viewModel: VideoViewModel
    @StateObject private var favoritesViewModel: PlaylistFavoritesViewModel
    
    private let playlistId: String
    private let context: ModelContext

    init(playlistId: String, context: ModelContext) {
        self.playlistId = playlistId
        self.context = context
        _viewModel = StateObject(wrappedValue: VideoViewModel(playlistId: playlistId, context: context))
        _favoritesViewModel = StateObject(wrappedValue: PlaylistFavoritesViewModel(context: context))
    }
    
    private var title: String {
        let t = viewModel.playlistTitle
        return t.isEmpty ? "🎥 Playlist" : t
    }

    var body: some View {
        NavigationStack {
            List(viewModel.filteredVideos) { video in
                VideoRow(video: video)
            }
            .task {
                await viewModel.loadVideos()
                favoritesViewModel.reload()
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { @MainActor in
                            await favoritesViewModel.toggleFavorite(
                                id: playlistId,
                                title: viewModel.playlistTitle.isEmpty ? "Playlist" : viewModel.playlistTitle,
                                thumbnailURL: viewModel.playlistThumbnailURL
                            )
                        }
                    } label: {
                        Image(systemName: favoritesViewModel.isFavorite(id: playlistId) ? "heart.fill" : "heart")
                    }
                }
            }
        }
    }
}

#Preview {
    EmptyView()
}
