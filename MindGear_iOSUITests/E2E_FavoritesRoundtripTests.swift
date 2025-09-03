import XCTest

final class E2E_FavoritesRoundtripTests: XCTestCase {
    func testFavoritesVideoRoundtrip() {
        // Given
        let app = XCUIApplication()
        app.launchArguments += ["-UITest_reset"]
        app.launchEnvironment["UITest_hasSeenOnboarding"] = "true"
        app.launch()

        // When: Video öffnen und als Favorit markieren
        let firstVideo = app.cells.element(boundBy: 0)
        firstVideo.waitForExistence(timeout: 8)
        XCTAssertTrue(firstVideo.exists && firstVideo.isHittable, "Kein Video gefunden")
        firstVideo.tap()

        let candidates = [app.buttons["favoriteButton"], app.buttons["heartButton"], app.buttons.element(boundBy: 0)]
        let favoriteButton = candidates.first {
            $0.waitForExistence(timeout: 2)
            return $0.exists && $0.isHittable
        }
        XCTAssertNotNil(favoriteButton, "Kein Favoriten-Button gefunden")
        favoriteButton?.tap()

        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        backButton.waitForExistence(timeout: 4)
        if backButton.exists { backButton.tap() }

        // Then: In Favoriten wechseln und löschen
        let favoritesTab: XCUIElement
        if app.tabBars.buttons["Favoriten"].exists {
            favoritesTab = app.tabBars.buttons["Favoriten"]
        } else {
            favoritesTab = app.tabBars.buttons.element(boundBy: 2)
        }
        favoritesTab.waitForExistence(timeout: 8)
        XCTAssertTrue(favoritesTab.exists && favoritesTab.isHittable, "Favoriten-Tab nicht gefunden")
        favoritesTab.tap()

        let videosSegment = app.buttons["favoritesVideosTab"]
        videosSegment.waitForExistence(timeout: 8)
        XCTAssertTrue(videosSegment.exists && videosSegment.isHittable, "Videos-Segment fehlt")
        videosSegment.tap()

        let favoriteCell = app.cells.element(boundBy: 0)
        favoriteCell.waitForExistence(timeout: 8)
        XCTAssertTrue(favoriteCell.exists, "Favorit wurde nicht hinzugefügt")
        let initialCount = app.cells.count
        favoriteCell.swipeLeft()
        let delete = [app.buttons["favoritesDeleteButton"], app.buttons["Löschen"], app.buttons["Delete"]].first { $0.exists }
        XCTAssertNotNil(delete, "Löschen-Button nicht gefunden")
        delete?.tap()
        favoriteCell.waitToDisappear(timeout: 8)
        XCTAssertTrue(app.cells.count < initialCount, "Favoritenliste sollte kleiner werden")
    }
}
