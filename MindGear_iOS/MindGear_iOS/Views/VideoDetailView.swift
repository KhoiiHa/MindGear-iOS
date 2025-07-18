import SwiftUI

struct VideoDetailView: View {
    let video: Video
    @State private var isFavorite: Bool

    init(video: Video) {
        self.video = video
        self._isFavorite = State(initialValue: video.isFavorite)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Thumbnail
                if let url = URL(string: video.thumbnailURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                // Title
                Text(video.title)
                    .font(.title)
                    .fontWeight(.bold)

                // Description
                Text(video.description)
                    .font(.body)
                    .foregroundColor(.secondary)

                // Favorite button
                Button(action: {
                    isFavorite.toggle()
                }) {
                    HStack {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .gray)
                        Text(isFavorite ? "Favorit" : "Als Favorit markieren")
                            .foregroundColor(.accentColor)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Details")
    }
}

struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        VideoDetailView(video: Video(
            id: UUID(),
            title: "Beispielvideo",
            description: "Dies ist eine Beschreibung.",
            thumbnailURL: "https://placehold.co/600x400",
            videoURL: "https://youtube.com/watch?v=xyz",
            category: "Motivation"
        ))
    }
}
