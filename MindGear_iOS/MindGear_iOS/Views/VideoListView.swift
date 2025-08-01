import SwiftUI
import SwiftData

struct VideoListView: View {
    @StateObject private var viewModel: VideoViewModel

    init(context: ModelContext) {
        _viewModel = StateObject(
            wrappedValue: VideoViewModel(
                playlistId: ConfigManager.recommendedPlaylistId,
                context: context
            )
        )
    }
    var body: some View {
        NavigationView {
            List(viewModel.filteredVideos) { video in
                NavigationLink(destination: VideoDetailView(video: video)) {
                    VideoRow(video: video)
                }
            }
            .navigationTitle("Videos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Toggle(isOn: $viewModel.showFavoritesOnly) {
                        Image(systemName: viewModel.showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundColor(viewModel.showFavoritesOnly ? .red : .gray)
                    }
                    .toggleStyle(.button)
                    .accessibilityLabel("Nur Favoriten anzeigen")
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Suche Videos")
            .task {
                await viewModel.loadVideos()
            }
            .alert(
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { newValue in
                        if !newValue {
                            viewModel.errorMessage = nil
                        }
                    }
                ),
                content: {
                    Alert(
                        title: Text("Fehler"),
                        message: Text(viewModel.errorMessage ?? "Ein unbekannter Fehler ist aufgetreten."),
                        dismissButton: .default(Text("OK"), action: {
                            viewModel.errorMessage = nil
                        })
                    )
                }
            )
            .overlay(
                Group {
                    if let message = viewModel.offlineMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }, alignment: .top
            )
        }
    }
}

struct VideoListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            let container = try! ModelContainer(for: FavoriteVideoEntity.self)
            VideoListView(context: container.mainContext)
        }
    }
}
