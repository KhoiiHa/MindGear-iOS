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
            set: { newValue in viewModel.updateSearch(text: newValue) }
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

    // Schlankes Suchfeld – Debounce steckt im ViewModel
    private var headerSearch: some View {
        SearchField(
            text: Binding(
                get: { viewModel.searchText },
                set: { viewModel.updateSearch(text: $0) }
            ),
            suggestions: suggestionItems,
            onSubmit: { viewModel.commitSearchTerm() },
            onTapSuggestion: { s in
                viewModel.updateSearch(text: s)
                viewModel.commitSearchTerm()
            }
        )
        .padding(.horizontal)
        .padding(.top, 8)
        .accessibilityLabel("Suche")
        .accessibilityHint("Eingeben, um Ergebnisse zu filtern.")
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
            .safeAreaInset(edge: .top) {
                headerSearch
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
                            .accessibilityLabel(favoritesViewModel.isFavorite(id: playlistId) ? "Playlist aus Favoriten entfernen" : "Playlist zu Favoriten hinzufügen")
                            .accessibilityHint("Favoritenstatus der Playlist ändern.")
                    }
                }
            }
        }
    }
}

#Preview {
    EmptyView()
}
