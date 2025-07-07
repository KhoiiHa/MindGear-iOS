import SwiftUI
import SwiftData

struct FavoritenView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: FavoritenViewModel

    init() {
        let container = try! ModelContainer(for: FavoriteVideoEntity.self)
        let context = container.mainContext
        _viewModel = StateObject(wrappedValue: FavoritenViewModel(context: context))
    }

    var body: some View {
        NavigationView {
            List {
                if viewModel.favorites.isEmpty {
                    Text("Keine Favoriten gespeichert.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.favorites, id: \.id) { favorite in
                        VStack(alignment: .leading) {
                            Text(favorite.title)
                                .font(.headline)
                            Text(favorite.videoDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let favorite = viewModel.favorites[index]
                            FavoritesManager.shared.toggleFavorite(
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
                        }
                        viewModel.loadFavorites(context: context)
                    }
                }
            }
            .navigationTitle("Favoriten")
            .onAppear {
                viewModel.loadFavorites(context: context)
            }
        }
    }
}

struct FavoritenView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritenView()
    }
}
