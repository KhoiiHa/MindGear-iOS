import XCTest

final class E2E_OnboardingFlowTests: XCTestCase {
    func testOnboardingFlow() {
        // Given
        let app = XCUIApplication()
        app.launchArguments += ["-UITest_reset"]
        app.launchEnvironment["UITest_hasSeenOnboarding"] = "false"

        // When
        app.launch()
        let next = app.buttons["onboardingNextButton"]
        next.waitForExistence(timeout: 8)
        XCTAssertTrue(next.exists && next.isHittable, "Weiter-Button fehlt")
        next.tap()
        next.waitForExistence(timeout: 8)
        XCTAssertTrue(next.exists && next.isHittable, "Weiter-Button nach erstem Tap nicht sichtbar")
        next.tap()
        let start = app.buttons["onboardingStartButton"]
        start.waitForExistence(timeout: 8)
        XCTAssertTrue(start.exists && start.isHittable, "Start-Button fehlt")
        start.tap()

        // Then
        let tabBar = app.tabBars.firstMatch
        tabBar.waitForExistence(timeout: 8)
        XCTAssertTrue(tabBar.exists, "Tab-Bar sollte erscheinen")
    }
}
