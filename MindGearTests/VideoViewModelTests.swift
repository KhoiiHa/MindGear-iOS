import XCTest
import SwiftData
@testable import MindGear_iOS

final class VideoViewModelTests: XCTestCase {
    func testLoadVideosSuccess() async {
        let snippet = Snippet(title: "t", description: "d", thumbnails: Thumbnails(medium: Thumbnail(url: "thumb")), resourceId: ResourceID(videoId: "id"))
        let item = YouTubeVideoItem(snippet: snippet)
        let mock = MockAPIService(result: .success([item]))
        let schema = Schema([FavoriteVideoEntity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let viewModel = VideoViewModel(apiService: mock, context: container.mainContext)

        await viewModel.loadVideos()

        XCTAssertEqual(viewModel.videos.count, 1)
        XCTAssertEqual(viewModel.videos.first?.title, "t")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadVideosFailure() async {
        let mock = MockAPIService(result: .failure(AppError.networkError))
        let schema = Schema([FavoriteVideoEntity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let viewModel = VideoViewModel(apiService: mock, context: container.mainContext)

        await viewModel.loadVideos()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.videos.isEmpty)
    }
}
