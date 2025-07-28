import SwiftUI
import SwiftData

struct VideoListView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: VideoViewModel

    init() {
        _viewModel = StateObject(wrappedValue: VideoViewModel(context: nil))
    }

    var body: some View {
        NavigationView {
            List(viewModel.filteredVideos) { video in
                HStack(spacing: 12) {
                    // Thumbnail
                    if let url = URL(string: video.thumbnailURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
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

                    // Title & Description
                    VStack(alignment: .leading, spacing: 4) {
                        Text(video.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(video.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(.vertical, 6)
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
                viewModel.updateContext(context)
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
            VideoListView()
        }
    }
}
