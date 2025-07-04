
import Foundation

final class VideoManager {
    static let shared = VideoManager()

    private init() {}

    func getSampleVideos() -> [Video] {
        return [
            Video(
                id: UUID(),
                title: "Die Kraft der Achtsamkeit",
                description: "Ein inspirierendes Video über Achtsamkeit im Alltag.",
                thumbnailURL: URL(string: "https://example.com/thumbnail1.jpg")!,
                videoURL: URL(string: "https://youtube.com/watch?v=xyz")!,
                category: "Achtsamkeit"
            ),
            Video(
                id: UUID(),
                title: "Mentale Stärke entwickeln",
                description: "Tipps und Übungen für mehr mentale Widerstandskraft.",
                thumbnailURL: URL(string: "https://example.com/thumbnail2.jpg")!,
                videoURL: URL(string: "https://youtube.com/watch?v=abc")!,
                category: "Motivation"
            )
        ]
    }
}

