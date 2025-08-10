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
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.15)
                                .frame(width: 80, height: 60)
                                .cornerRadius(8)
                        case .success(let image):
                            image.resizable().scaledToFill()
                                .frame(width: 80, height: 60)
                                .cornerRadius(8)
                        case .failure:
                            Image(systemName: "photo")
                                .frame(width: 80, height: 60)
                                .foregroundColor(.gray)
                        @unknown default:
                            Image(systemName: "photo")
                                .frame(width: 80, height: 60)
                                .foregroundColor(.gray)
                        }
                    }
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

    var body: some View {
        NavigationView {
            List {
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
            .overlay {
                if viewModel.favorites.isEmpty && viewModel.favoriteMentors.isEmpty && searchText.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Favoriten",
                        systemImage: "star",
                        description: Text("Markiere Videos oder Mentoren mit dem Herz.")
                    )
                }
            }
            .navigationTitle("Favoriten")
            .searchable(text: $searchText, prompt: "Favoriten durchsuchen")
            .toolbar { EditButton() }
            .onAppear {
            }
        }
    }
}
