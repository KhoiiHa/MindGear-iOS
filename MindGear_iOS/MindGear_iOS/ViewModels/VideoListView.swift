import SwiftUI

struct VideoListView: View {
    @StateObject private var viewModel = VideoViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.videos) { video in
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
