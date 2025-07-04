import Foundation

class VideoViewModel: ObservableObject {
    @Published var videos: [Video] = []

    init() {
        loadSampleVideos()
    }

    func loadSampleVideos() {
        self.videos = VideoManager.shared.getSampleVideos()
    }

    func toggleFavorite(for video: Video) {
        if let index = videos.firstIndex(of: video) {
            videos[index].isFavorite.toggle()
        }
    }
}
