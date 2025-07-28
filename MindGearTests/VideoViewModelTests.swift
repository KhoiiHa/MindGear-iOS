import XCTest
@testable import MindGear_iOS

final class VideoViewModelTests: XCTestCase {
    func testLoadVideosSuccess() async {
        let snippet = Snippet(title: "t", description: "d", thumbnails: Thumbnails(medium: Thumbnail(url: "thumb")), resourceId: ResourceID(videoId: "id"))
        let item = YouTubeVideoItem(snippet: snippet)
        let mock = MockAPIService(result: .success([item]))
        let viewModel = VideoViewModel(apiService: mock)

        await viewModel.loadVideos()

        XCTAssertEqual(viewModel.videos.count, 1)
        XCTAssertEqual(viewModel.videos.first?.title, "t")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadVideosFailure() async {
        let mock = MockAPIService(result: .failure(AppError.networkError))
        let viewModel = VideoViewModel(apiService: mock)

        await viewModel.loadVideos()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.videos.isEmpty)
    }
}
