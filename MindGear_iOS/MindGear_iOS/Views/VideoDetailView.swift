import SwiftUI

struct VideoDetailView: View {
    let video: Video
    @State private var isFavorite: Bool

    init(video: Video) {
        self.video = video
        self._isFavorite = State(initialValue: video.isFavorite)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(video.title)
                .font(.title)
                .fontWeight(.bold)

            Text(video.description)
                .font(.body)
                .foregroundColor(.secondary)

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
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Details")
    }
}

struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        VideoDetailView(video: Video(
            id: UUID(),
            title: "Beispielvideo",
            description: "Dies ist eine Beschreibung.",
            thumbnailURL: URL(string: "https://example.com/thumbnail.jpg")!,
            videoURL: URL(string: "https://youtube.com/watch?v=xyz")!,
            category: "Motivation"
        ))
    }
}
