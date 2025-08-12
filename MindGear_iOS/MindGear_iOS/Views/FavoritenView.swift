import SwiftUI
import SwiftData

struct FavoritenView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: FavoritenViewModel
    @State private var searchText = ""

    init(context: ModelContext) {
        _viewModel = StateObject(wrappedValue: FavoritenViewModel(context: context))
    }

    private var filteredFavorites: [FavoriteVideoEntity] {
        if searchText.isEmpty {
            return viewModel.favorites
        } else {
            return viewModel.favorites.filter { favorite in
                favorite.title.localizedCaseInsensitiveContains(searchText) ||
                favorite.videoDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private var filteredMentorFavorites: [FavoriteMentorEntity] {
        if searchText.isEmpty { return viewModel.favoriteMentors }
        return viewModel.favoriteMentors.filter { fav in
            fav.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredPlaylistFavorites: [FavoritePlaylistEntity] {
        if searchText.isEmpty { return viewModel.favoritePlaylists }
        return viewModel.favoritePlaylists.filter { fav in
            fav.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    // Autovervollständigung: Vorschläge aus allen Favoriten (Videos, Mentoren, Playlists)
    private var suggestionItems: [String] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard q.count >= 2 else { return [] }

        let titles = viewModel.favorites.map { $0.title } 
                   + viewModel.favoriteMentors.map { $0.name } 
                   + viewModel.favoritePlaylists.map { $0.title }

        let prefix = titles.filter { $0.lowercased().hasPrefix(q) }
        let rest = titles.filter { $0.lowercased().contains(q) && !$0.lowercased().hasPrefix(q) }
        var merged: [String] = []
        for t in (prefix + rest) where !merged.contains(t) {
            merged.append(t)
        }
        return Array(merged.prefix(6))
    }

    // MARK: - Row-Views ausgelagert (entlastet den Type-Checker)
    private struct VideoFavoriteCell: View {
        let fav: FavoriteVideoEntity
        var body: some View {
            HStack(spacing: 12) {
                if let data = fav.thumbnailData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFill()
                        .frame(width: 80, height: 60)
                        .cornerRadius(8)
                } else if let url = URL(string: fav.thumbnailURL) {
                    ThumbnailView(urlString: url.absoluteString, width: 80, height: 60, cornerRadius: 8)
                }
                VStack(alignment: .leading) {
                    Text(fav.title).font(.headline)
                    Text(fav.videoDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private struct MentorFavoriteCell: View {
        let fav: FavoriteMentorEntity
        var body: some View {
            HStack(spacing: 12) {
                if let url = URL(string: fav.profileImageURL), let scheme = url.scheme, scheme.hasPrefix("http") {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.15)
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            Image(systemName: "person.crop.circle")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        @unknown default:
                            Image(systemName: "person.crop.circle")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                        .frame(width: 44, height: 44)
                }

                VStack(alignment: .leading) {
                    Text(fav.name).font(.headline)
                    Text(fav.id)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "heart.fill").foregroundColor(.red)
            }
        }
    }
    
    private struct PlaylistFavoriteCell: View {
        let fav: FavoritePlaylistEntity
        var body: some View {
            HStack(spacing: 12) {
                if let url = URL(string: fav.thumbnailURL), let scheme = url.scheme, scheme.hasPrefix("http") {
                    ThumbnailView(urlString: url.absoluteString, width: 80, height: 60, cornerRadius: 8)
                        .frame(width: 80, height: 60)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "rectangle.stack")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .frame(width: 80, height: 60)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(fav.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(fav.id)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Delete Helper
    private func deleteVideoFavorites(at offsets: IndexSet) {
        for index in offsets {
            let fav = filteredFavorites[index]
            Task { @MainActor in
                await FavoritesManager.shared.toggleVideoFavorite(
                    video: Video(
                        id: fav.id,
                        title: fav.title,
                        description: fav.videoDescription,
                        thumbnailURL: fav.thumbnailURL,
                        videoURL: fav.videoURL,
                        category: fav.category
                    ),
                    context: context
                )
            }
        }
    }

    private func deleteMentorFavorites(at offsets: IndexSet) {
        for index in offsets {
            let fav = filteredMentorFavorites[index]
            context.delete(fav)
        }
        do { try context.save() } catch { print("Save failed (mentor favorite delete):", error) }
        NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
    }
    
    private func deletePlaylistFavorites(at offsets: IndexSet) {
        for index in offsets {
            let fav = filteredPlaylistFavorites[index]
            context.delete(fav)
        }
        do { try context.save() } catch { print("Save failed (playlist favorite delete):", error) }
        NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
    }

    // MARK: - Section Builder
    @ViewBuilder
    private func videoSection() -> some View {
        Section {
            if filteredFavorites.isEmpty {
                Text(viewModel.favorites.isEmpty ? "Keine Video-Favoriten." : "Keine Videos gefunden.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(filteredFavorites, id: \.id) { fav in
                    VideoFavoriteCell(fav: fav)
                }
                .onDelete(perform: deleteVideoFavorites)
            }
        } header: {
            Text("📺 Videos")
        } footer: {
            Text("Tipp: Nach links wischen, um Video-Favoriten zu entfernen.")
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func mentorSection() -> some View {
        Section {
            if filteredMentorFavorites.isEmpty {
                Text(viewModel.favoriteMentors.isEmpty ? "Keine Mentor-Favoriten." : "Keine Mentoren gefunden.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(filteredMentorFavorites, id: \.id) { fav in
                    MentorFavoriteCell(fav: fav)
                }
                .onDelete(perform: deleteMentorFavorites)
            }
        } header: {
            Text("👤 Mentoren")
        } footer: {
            Text("Tipp: Nach links wischen, um Mentor-Favoriten zu entfernen.")
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func playlistSection() -> some View {
        Section {
            if filteredPlaylistFavorites.isEmpty {
                Text(viewModel.favoritePlaylists.isEmpty ? "Keine Playlist-Favoriten." : "Keine Playlists gefunden.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(filteredPlaylistFavorites, id: \.id) { fav in
                    NavigationLink(destination: VideoListView(playlistID: fav.id, context: context)) {
                        PlaylistFavoriteCell(fav: fav)
                    }
                }
                .onDelete(perform: deletePlaylistFavorites)
            }
        } header: {
            Text("📁 Playlists")
        } footer: {
            Text("Tipp: Nach links wischen, um Playlist-Favoriten zu entfernen.")
                .foregroundColor(.secondary)
        }
    }

    var body: some View {
        NavigationView {
            List {
                videoSection()
                mentorSection()
                playlistSection()
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Favoriten")
            .searchable(text: $searchText, prompt: "Favoriten durchsuchen")
            .searchSuggestions {
                let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count >= 2 {
                    ForEach(suggestionItems, id: \.self) { suggestion in
                        Button(action: {
                            searchText = suggestion
                        }) {
                            Text(suggestion)
                        }
                        .searchCompletion(suggestion)
                    }
                }
            }
            .toolbar { EditButton() }
            .onAppear {
                viewModel.loadFavorites()
            }
        }
    }
}
