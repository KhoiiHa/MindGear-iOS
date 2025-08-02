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

    init(playlistId: String, context: ModelContext) {
        _viewModel = StateObject(wrappedValue: VideoViewModel(playlistId: playlistId, context: context))
    }
    
    private var title: String {
        viewModel.filteredVideos.first?.category ?? "🎥 Playlist"
    }

    var body: some View {
        NavigationStack {
            List(viewModel.filteredVideos) { video in
                VideoRow(video: video)
            }
            .task {
                await viewModel.loadVideos()
            }
            .navigationTitle(title)
        }
    }
}

#Preview {
    EmptyView()
}
