import XCTest

final class E2E_MindGearTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // T1 – Onboarding-Flow
    func testT1_OnboardingFlow() {
        app.launchArguments += ["-resetOnboarding", "YES"]
        app.launch()
        app.buttons["onboardingNextButton"].tap()
        app.buttons["onboardingNextButton"].tap()
        app.buttons["onboardingStartButton"].tap()
        app.tabBars.firstMatch.waitForExistence()
        takeScreenshot("T1_onboarding_main", app: app)
    }

    // T2 – Mentoren-Suche
    func testT2_MentorSearch() {
        app.launchArguments += ["-resetOnboarding", "NO"]
        app.launch()
        let searchField = app.searchFields["mentorSearchField"]
        searchField.waitForExistence()
        searchField.tap()
        searchField.typeText("Shaolin")
        let mentorCell = app.cells.element(matchingIdentifierPrefix: "mentorCell_")
        mentorCell.waitForExistence()
        takeScreenshot("T2_mentors_search", app: app)
    }

    // T3 – Playlist aus Mentor-Detail
    func testT3_PlaylistFromMentor() {
        app.launchArguments += ["-resetOnboarding", "NO"]
        app.launch()
        let mentorCell = app.cells.element(matchingIdentifierPrefix: "mentorCell_")
        mentorCell.waitForExistence()
        mentorCell.tap()
        let firstPlaylist = app.cells.element(boundBy: 0)
        firstPlaylist.waitForExistence()
        firstPlaylist.tap()
        let playlistSearch = app.searchFields["playlistSearchField"]
        playlistSearch.waitForExistence()
        takeScreenshot("T3_playlist_view", app: app)
    }

    // T4 – Favoriten Roundtrip (Video)
    func testT4_FavoritesVideoRoundtrip() {
        app.launchArguments += ["-resetOnboarding", "NO"]
        app.launch()
        let videoCell = app.cells.element(matchingIdentifierPrefix: "videoCell_")
        videoCell.waitForExistence()
        videoCell.tap()

        let favoriteButton = app.buttons["favoriteButton"]
        favoriteButton.waitForExistence()
        favoriteButton.tap()

        app.tabBars.buttons.element(boundBy: 2).tap()
        let videosTab = app.buttons["favoritesVideosTab"]
        videosTab.waitForExistence()
        videosTab.tap()

        let favVideo = app.cells.element(matchingIdentifierPrefix: "videoCell_")
        favVideo.waitForExistence()
        takeScreenshot("T4_favorites_videos", app: app)

        favVideo.swipeLeft()
        favVideo.buttons.element(boundBy: 0).tap()
        favVideo.waitToDisappear()
    }

    // T5 – Notifications-Stub (Settings)
    func testT5_NotificationsToggle() {
        app.launchArguments += ["-resetOnboarding", "NO"]
        app.launch()
        app.tabBars.buttons.element(boundBy: 3).tap()

        let toggle = app.switches["notificationsToggle"]
        toggle.waitForExistence()

        addUIInterruptionMonitor(withDescription: "Permissions") { alert in
            if alert.buttons["Allow"].exists {
                alert.buttons["Allow"].tap()
                return true
            }
            if alert.buttons["Erlauben"].exists {
                alert.buttons["Erlauben"].tap()
                return true
            }
            return false
        }

        if toggle.value as? String == "0" {
            toggle.tap()
        }
        app.tap()
        XCTAssertEqual(toggle.value as? String, "1")
        takeScreenshot("T5_settings_notifications", app: app)
    }

    // T6 – Performance-Smoke (Scroll)
    func testT6_ScrollSmoke() {
        app.launchArguments += ["-resetOnboarding", "NO"]
        app.launch()
        let firstVideo = app.cells.element(matchingIdentifierPrefix: "videoCell_")
        firstVideo.waitForExistence()
        for _ in 0..<3 { firstVideo.swipeUp() }
        for _ in 0..<3 { firstVideo.swipeDown() }
        XCTAssertTrue(firstVideo.isHittable)
        takeScreenshot("T6_scroll_smoke", app: app)
    }
}
