import SwiftUI
import SwiftData

struct FavoritenView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = FavoritenViewModel() 
    @State private var searchText = ""

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

    var body: some View {
        NavigationView {
            List {
                if filteredFavorites.isEmpty {
                    Text(viewModel.favorites.isEmpty
                         ? "Keine Favoriten gespeichert."
                         : "Keine Favoriten gefunden.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredFavorites, id: \.id) { favorite in
                        HStack(spacing: 12) {
                            if let data = favorite.thumbnailData,
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 60)
                                    .cornerRadius(8)
                            } else if let url = URL(string: favorite.thumbnailURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 80, height: 60)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 60)
                                            .cornerRadius(8)
                                    case .failure:
                                        Image(systemName: "photo")
                                            .frame(width: 80, height: 60)
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }

                            VStack(alignment: .leading) {
                                Text(favorite.title)
                                    .font(.headline)
                                Text(favorite.videoDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let favorite = filteredFavorites[index]
                            Task {
                                await FavoritesManager.shared.toggleFavorite(
                                    video: Video(
                                        id: favorite.id,
                                        title: favorite.title,
                                        description: favorite.videoDescription,
                                        thumbnailURL: favorite.thumbnailURL,
                                        videoURL: favorite.videoURL,
                                        category: favorite.category
                                    ),
                                    context: context
                                )
                                viewModel.loadFavorites(context: context)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favoriten")
            .searchable(text: $searchText, prompt: "Favoriten durchsuchen")
            .onAppear {
                viewModel.context = context
                viewModel.loadFavorites(context: context)
            }
        }
    }
}
