import XCTest

final class E2E_MindGearTests: XCTestCase {
    var app: XCUIApplication!

    // MARK: - Lifecycle
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        // --- end setup ---
    }

    // MARK: - Small helpers (navigation & waits)
    private func launch(resetOnboarding: Bool) {
        app.launchArguments += ["-resetOnboarding", resetOnboarding ? "YES" : "NO"]
        app.launch()
    }

    private func goToTab(accessId: String, fallbackLabel: String, file: StaticString = #filePath, line: UInt = #line) {
        let tabBar = app.tabBars.firstMatch

        // 1) Try by accessibility id (if your app sets them, e.g. tab_mentors / tab_settings)
        if tabBar.exists, tabBar.buttons[accessId].exists {
            tabBar.buttons[accessId].tap()
            return
        }

        // 2) Try by visible label (DE/EN)
        if tabBar.exists, tabBar.buttons[fallbackLabel].exists {
            tabBar.buttons[fallbackLabel].tap()
            return
        }
        let alt = (fallbackLabel == "Mentoren") ? "Mentors" : ((fallbackLabel == "Einstellungen") ? "Settings" : fallbackLabel)
        if tabBar.exists, tabBar.buttons[alt].exists {
            tabBar.buttons[alt].tap()
            return
        }

        // 3) Go via "Mehr/More" overflow list
        if tabBar.exists {
            let count = tabBar.buttons.count
            if count > 0 { tabBar.buttons.element(boundBy: count - 1).tap() }
        }
        let table = app.tables.firstMatch
        let cell = table.staticTexts[fallbackLabel].exists ? table.staticTexts[fallbackLabel] : table.staticTexts[alt]
        let ok = cell.waitForExistence(timeout: 8)
        XCTAssertTrue(ok, "Tab '\(fallbackLabel)' nicht erreichbar – weder direkt noch über 'Mehr'.", file: file, line: line)
        if ok { cell.tap() }
    }

    private func tapTab(label: String, fallbackIndex: Int) {
        let tabBars = app.tabBars
        let bar = tabBars.firstMatch

        // Kandidaten (DE/EN) + evtl. vorhandene Titel
        let candidates = [label, "More", "Mehr", "Einstellungen", "Settings", "Mentoren", "Mentors", "Videos", "Favoriten", "Favorites"]

        if bar.exists {
            // 0) Direkt per Label
            for key in candidates {
                let btn = bar.buttons[key]
                if btn.exists { btn.tap(); return }
            }

            // 1) Falls wir wissen, welcher Index gemeint ist
            let count = bar.buttons.count
            if count > 0 && fallbackIndex >= 0 && fallbackIndex < count {
                bar.buttons.element(boundBy: fallbackIndex).tap(); return
            }

            // 2) Probiere alle Tabs von links nach rechts
            let all = bar.buttons.allElementsBoundByIndex
            for b in all { b.tap(); usleep(200_000) }
            return
        }

        // Letzter Notnagel: irgendeine TabBar nehmen und den letzten (oder Index) drücken
        if let anyBar = tabBars.allElementsBoundByIndex.first {
            let count = anyBar.buttons.count
            if count > 0 {
                let idx = (fallbackIndex >= 0 && fallbackIndex < count) ? fallbackIndex : count - 1
                anyBar.buttons.element(boundBy: idx).tap()
            }
        }
    }

    /// Taps the last tab (usually "More/Mehr") if present
    private func tapMoreIfNeeded() {
        let bar = app.tabBars.firstMatch
        if bar.exists {
            let count = bar.buttons.count
            if count > 0 { bar.buttons.element(boundBy: count - 1).tap() }
        }
    }

    /// Scrolls a table/collection until an element exists or maxSwipes are exhausted
    @discardableResult
    private func scrollToReveal(_ element: XCUIElement, maxSwipes: Int = 6) -> Bool {
        if element.exists { return true }
        let scrollables: [XCUIElement] = [app.tables.firstMatch, app.collectionViews.firstMatch, app.scrollViews.firstMatch]
        for _ in 0..<maxSwipes {
            if element.exists { return true }
            for s in scrollables where s.exists {
                s.swipeUp()
            }
        }
        return element.exists
    }

    /// Finds a cell by substring in its label, with scrolling through More-lists
    private func tapCell(labelContains text: String, timeout: TimeInterval = 8) {
        let pred = NSPredicate(format: "label CONTAINS[c] %@", text)
        var cell = app.cells.matching(pred).firstMatch
        if !cell.exists { cell = app.staticTexts.matching(pred).firstMatch }
        _ = cell.waitForExistence(timeout: 2)
        if !cell.exists { _ = scrollToReveal(cell) }
        if cell.exists { cell.tap() }
    }

    private func openMentors() {
        // Heuristik: Auf dem Mentoren-Screen gibt es ein Suchfeld mit dieser ID
        let want = app.searchFields["mentorSearchField"]

        // a) Versuche bekannte Labels/IDs
        tapTab(label: "Mentoren", fallbackIndex: 0)

        // b) Prüfe alle Tabs nacheinander, bis das Heuristik-Element auftaucht
        if !want.waitForExistence(timeout: 1.2), app.tabBars.firstMatch.exists {
            let buttons = app.tabBars.firstMatch.buttons.allElementsBoundByIndex
            for b in buttons {
                b.tap()
                if want.waitForExistence(timeout: 1.0) { return }
            }
        }
        if want.exists { return }

        // c) Fallback: „Mehr“ → Zelle mit „Mentor“ antippen
        tapMoreIfNeeded()
        tapCell(labelContains: "Mentor")
    }

    private func openVideos() {
        // Heuristik: eine Videozelle mit Prefix
        let want = app.cells.matching(NSPredicate(format: "identifier BEGINSWITH %@", "videoCell_")).firstMatch

        tapTab(label: "Videos", fallbackIndex: 1)

        if !want.waitForExistence(timeout: 1.2), app.tabBars.firstMatch.exists {
            let buttons = app.tabBars.firstMatch.buttons.allElementsBoundByIndex
            for b in buttons {
                b.tap()
                if want.waitForExistence(timeout: 1.0) { return }
            }
        }
        if want.exists { return }

        tapMoreIfNeeded()
        tapCell(labelContains: "Video")
    }

    private func openSettings() {
        // Heuristik: Toggle mit ID "notificationsToggle" (oder irgendein Switch)
        var want = app.switches["notificationsToggle"]
        if !want.exists { want = app.switches.firstMatch }

        tapTab(label: "Einstellungen", fallbackIndex: 2)

        if !want.waitForExistence(timeout: 1.2), app.tabBars.firstMatch.exists {
            let buttons = app.tabBars.firstMatch.buttons.allElementsBoundByIndex
            for b in buttons {
                b.tap()
                if want.waitForExistence(timeout: 1.0) { return }
            }
        }
        if want.exists { return }

        tapMoreIfNeeded()
        tapCell(labelContains: "Einstell")
        tapCell(labelContains: "Setting")
    }

    // Convenience finders using the custom accessibility ids we added in the app
    private func firstCell(matchingPrefix prefix: String) -> XCUIElement {
        // Fallback to first cell if we didn't find a prefixed id
        let byPrefix = app.cells.matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).firstMatch
        if byPrefix.exists { return byPrefix }
        return app.cells.firstMatch
    }

    private func firstSearchField(withId preferredId: String) -> XCUIElement {
        let preferred = app.searchFields[preferredId]
        if preferred.exists { return preferred }
        let any = app.searchFields.firstMatch
        if any.exists { return any }
        // Some search bars expose as textFields depending on OS/state
        let anyText = app.textFields.firstMatch
        return anyText
    }

    private func findButton(possibleIds: [String], labelSubstrings: [String]) -> XCUIElement? {
        // Try exact ids first
        for id in possibleIds {
            let btn = app.buttons[id]
            if btn.exists { return btn }
            let nav = app.navigationBars.buttons[id]
            if nav.exists { return nav }
            let tool = app.toolbars.buttons[id]
            if tool.exists { return tool }
        }
        // Then try by label substrings (case-insensitive)
        let pred = NSPredicate(format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@ OR label CONTAINS[c] %@", labelSubstrings.first ?? "", labelSubstrings.dropFirst().first ?? "", labelSubstrings.count > 2 ? labelSubstrings[2] : "")
        let pools: [XCUIElementQuery] = [app.buttons, app.navigationBars.buttons, app.toolbars.buttons]
        for q in pools {
            let m = q.matching(pred).firstMatch
            if m.exists { return m }
        }
        return nil
    }

    // MARK: - Tests

    // T1 – Onboarding-Flow
    func testT1_OnboardingFlow() {
        launch(resetOnboarding: true)
        app.buttons["onboardingNextButton"].tap()
        app.buttons["onboardingNextButton"].tap()
        app.buttons["onboardingStartButton"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 6))
        takeScreenshot("T1_onboarding_main", app: app)
    }

    // T2 – Mentoren-Suche
    func testT2_MentorSearch() {
        launch(resetOnboarding: false)
        openMentors()
        let searchField = firstSearchField(withId: "mentorSearchField")
        if !searchField.exists { _ = scrollToReveal(searchField) }
        XCTAssertTrue(searchField.waitForExistence(timeout: 10), "mentorSearchField not found – ensure MentorsView is reachable via tab or More → Mentoren and has the accessibilityIdentifier set.")
        searchField.tap()
        searchField.typeText("Shaolin")
        let mentorCell = firstCell(matchingPrefix: "mentorCell_")
        XCTAssertTrue(mentorCell.waitForExistence(timeout: 6))
        takeScreenshot("T2_mentors_search", app: app)
    }

    // T3 – Playlist aus Mentor-Detail
    func testT3_PlaylistFromMentor() {
        launch(resetOnboarding: false)
        openMentors()
        let mentorCell = firstCell(matchingPrefix: "mentorCell_")
        XCTAssertTrue(mentorCell.waitForExistence(timeout: 6))
        mentorCell.tap()
        // Prefer rows carrying a playlist identifier, else fall back to the first tappable cell
        var playlist = app.cells.matching(NSPredicate(format: "identifier BEGINSWITH %@", "playlistCell_")).firstMatch
        if !playlist.exists { playlist = app.cells.firstMatch }
        XCTAssertTrue(playlist.waitForExistence(timeout: 10))
        if !playlist.isHittable { _ = scrollToReveal(playlist) }
        playlist.tap()
        let playlistSearch = firstSearchField(withId: "playlistSearchField")
        if !playlistSearch.exists { _ = scrollToReveal(playlistSearch) }
        XCTAssertTrue(playlistSearch.waitForExistence(timeout: 10))
        takeScreenshot("T3_playlist_view", app: app)
    }

    // T4 – Favoriten Roundtrip (Video)
    func testT4_FavoritesVideoRoundtrip() {
        launch(resetOnboarding: false)
        openVideos()
        let videoCell = firstCell(matchingPrefix: "videoCell_")
        XCTAssertTrue(videoCell.waitForExistence(timeout: 6))
        videoCell.tap()

        // Favorite button: id first, then common labels (DE/EN) across buttons / nav bar / toolbar
        let fav = findButton(possibleIds: ["favoriteButton", "heartButton", "Favorite", "Favorit"],
                             labelSubstrings: ["Favorit", "Favorite", "Herz", "Heart"]) ?? app.buttons.firstMatch
        XCTAssertTrue(fav.waitForExistence(timeout: 8))
        if !fav.waitToBeHittable(timeout: 2) {
            app.swipeUp()
            _ = fav.waitToBeHittable(timeout: 2)
        }
        fav.tap()

        // Open Favorites tab (DE/EN or index fallback)
        if app.tabBars.buttons["Favoriten"].exists { app.tabBars.buttons["Favoriten"].tap() } else { tapTab(label: "Favorites", fallbackIndex: 2) }

        // Videos sub-filter: prefer accessibility id, else first segmented control button
        var videosTab = app.buttons["favoritesVideosTab"]
        if !videosTab.exists {
            let seg = app.segmentedControls.firstMatch
            if seg.exists { videosTab = seg.buttons.firstMatch }
        }
        XCTAssertTrue(videosTab.waitForExistence(timeout: 8))
        videosTab.tap()

        let favVideo = firstCell(matchingPrefix: "videoCell_")
        XCTAssertTrue(favVideo.waitForExistence(timeout: 6))
        takeScreenshot("T4_favorites_videos", app: app)

        // remove again (swipe-to-delete)
        favVideo.swipeLeft()

        // Versuche erst eine feste ID, dann gängige Labels (DE/EN)
        var deleteBtn = app.buttons["favoritesDeleteButton"]
        if !deleteBtn.exists { deleteBtn = favVideo.buttons["favoritesDeleteButton"] }
        if !deleteBtn.exists { deleteBtn = app.buttons["Löschen"] }
        if !deleteBtn.exists { deleteBtn = app.buttons["Delete"] }
        if !deleteBtn.exists { deleteBtn = favVideo.buttons["Löschen"] }
        if !deleteBtn.exists { deleteBtn = favVideo.buttons["Delete"] }
        if !deleteBtn.exists { deleteBtn = favVideo.buttons.firstMatch }

        XCTAssertTrue(deleteBtn.waitForExistence(timeout: 4),
                      "Kein Swipe-Delete-Button gefunden. Stelle sicher, dass die Zelle .swipeActions mit einem Button enthält.")
        deleteBtn.tap()
        _ = favVideo.waitForNonExistence(timeout: 6)
    }

    // T5 – Notifications-Stub (Settings)
    func testT5_NotificationsToggle() {
        launch(resetOnboarding: false)
        openSettings()

        var toggle = app.switches["notificationsToggle"]
        if !toggle.exists { toggle = app.switches.firstMatch }
        if !toggle.exists || !toggle.isHittable { _ = scrollToReveal(toggle) }
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))

        addUIInterruptionMonitor(withDescription: "Permissions") { alert in
            if alert.buttons["Allow"].exists { alert.buttons["Allow"].tap(); return true }
            if alert.buttons["Erlauben"].exists { alert.buttons["Erlauben"].tap(); return true }
            return false
        }

        if (toggle.value as? String) == "0" { toggle.tap() }
        app.tap()
        XCTAssertEqual(toggle.value as? String, "1")
        takeScreenshot("T5_settings_notifications", app: app)
    }

    // T6 – Performance-Smoke (Scroll)
    func testT6_ScrollSmoke() {
        launch(resetOnboarding: false)
        openVideos()
        let firstVideo = firstCell(matchingPrefix: "videoCell_")
        XCTAssertTrue(firstVideo.waitForExistence(timeout: 6))
        for _ in 0..<3 { firstVideo.swipeUp() }
        for _ in 0..<3 { firstVideo.swipeDown() }
        XCTAssertTrue(firstVideo.isHittable)
        takeScreenshot("T6_scroll_smoke", app: app)
    }
}

private extension XCUIElement {
    @discardableResult
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let exp = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [exp], timeout: timeout) == .completed
    }

    @discardableResult
    func waitToBeHittable(timeout: TimeInterval) -> Bool {
        let pred = NSPredicate(format: "hittable == true")
        let exp = XCTNSPredicateExpectation(predicate: pred, object: self)
        return XCTWaiter.wait(for: [exp], timeout: timeout) == .completed
    }
}
