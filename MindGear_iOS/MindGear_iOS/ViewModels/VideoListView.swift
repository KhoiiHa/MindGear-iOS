import SwiftUI

struct VideoListView: View {
    @StateObject private var viewModel = VideoViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.videos) { video in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(video.title)
                                .font(.headline)
                            Text(video.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            viewModel.toggleFavorite(for: video)
                        }) {
                            Image(systemName: video.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(video.isFavorite ? .red : .gray)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Videos")
        }
    }
}

struct VideoListView_Previews: PreviewProvider {
    static var previews: some View {
        VideoListView()
    }
}
