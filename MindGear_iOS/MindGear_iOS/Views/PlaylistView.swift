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
    
    // Bidirektionales Binding zum ViewModel-Suchtext
    private var searchTextBinding: Binding<String> {
        Binding(
            get: { viewModel.searchText },
            set: { newValue in viewModel.updateQuery(newValue) }
        )
    }
    
    // Autovervollständigung: lokale Vorschläge aus den aktuell sichtbaren Videos
    private var suggestionItems: [String] {
        let q = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = q.lowercased()
        guard query.count >= 2 else { return [] }
    
        let titles = viewModel.filteredVideos.map { $0.title }
        let prefix = titles.filter { $0.lowercased().hasPrefix(query) }
        let rest = titles.filter { $0.lowercased().contains(query) && !$0.lowercased().hasPrefix(query) }
        var merged: [String] = []
        for t in (prefix + rest) where !merged.contains(t) {
            merged.append(t)
        }
        return Array(merged.prefix(6))
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
            .searchable(text: searchTextBinding, prompt: "Suche Videos")
            .searchSuggestions {
                let trimmed = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count >= 2 {
                    ForEach(suggestionItems, id: \.self) { suggestion in
                        Button {
                            viewModel.searchText = suggestion
                            viewModel.updateQuery(suggestion)
                            viewModel.commitSearchTerm()
                        } label: {
                            Text(suggestion)
                        }
                        .searchCompletion(suggestion)
                    }
                } else if !viewModel.searchHistory.isEmpty {
                    Section("Zuletzt gesucht") {
                        ForEach(viewModel.searchHistory.prefix(5), id: \.self) { term in
                            Button {
                                viewModel.searchText = term
                                viewModel.updateQuery(term)
                            } label: {
                                Text(term)
                            }
                            .searchCompletion(term)
                        }
                        Button("Verlauf löschen", role: .destructive) {
                            viewModel.clearSearchHistory()
                        }
                    }
                }
            }
            .onSubmit(of: .search) {
                viewModel.commitSearchTerm()
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
