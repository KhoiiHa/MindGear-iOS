import XCTest
import SwiftData
@testable import MindGear_iOS

final class FavoritesManagerTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Schema([FavoriteVideoEntity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
    }

    func testToggleAndFetchFavorites() async throws {
        let video = Video(id: UUID(), title: "t", description: "d", thumbnailURL: "u", videoURL: "v", category: "c")
        let manager = FavoritesManager.shared

        XCTAssertFalse(manager.isFavorite(video: video, context: context))
        await manager.toggleFavorite(video: video, context: context)
        XCTAssertTrue(manager.isFavorite(video: video, context: context))

        let all = manager.getAllFavorites(context: context)
        XCTAssertEqual(all.count, 1)

        await manager.toggleFavorite(video: video, context: context)
        XCTAssertFalse(manager.isFavorite(video: video, context: context))
        XCTAssertTrue(manager.getAllFavorites(context: context).isEmpty)
    }
}
