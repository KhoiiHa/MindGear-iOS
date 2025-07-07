import SwiftUI

struct VideoListView: View {
    @StateObject private var viewModel = VideoViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.videos) { video in
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
                        // Optional: toggleFavorite ohne Context verwenden, falls nicht benötigt
                        // viewModel.toggleFavorite(video: video)
                    }) {
                        Image(systemName: "heart")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Videos")
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
