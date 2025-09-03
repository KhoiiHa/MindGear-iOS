import XCTest
@testable import MindGear_iOS

final class ConfigManagerTests: XCTestCase {
    func testConfigProvidesValues() {
        // When
        let playlistId = ConfigManager.recommendedPlaylistId
        let url = ConfigManager.apiBaseURL()

        // Then
        XCTAssertFalse(playlistId.isEmpty, "recommendedPlaylistId sollte nicht leer sein")
        XCTAssertNotNil(url.scheme, "apiBaseURL() sollte eine gültige URL liefern")
    }
}
