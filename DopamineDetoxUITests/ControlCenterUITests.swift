import XCTest

final class ControlCenterUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-hasOnboarded", "YES"]
        app.launch()
        return app
    }

    func testLaunchAndShowsControlCenter() {
        let app = launchedApp()
        XCTAssertTrue(app.staticTexts["Last Scroll"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Choose distraction apps"].exists)
    }

    func testStartDayDisabledWithoutSelection() {
        let app = launchedApp()
        let startButton = app.buttons["Start day"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        XCTAssertFalse(startButton.isEnabled)
    }

    func testSubmitStreakHiddenWhenSupabaseUnconfigured() {
        let app = launchedApp()
        XCTAssertTrue(app.staticTexts["Last Scroll"].waitForExistence(timeout: 5))
        // Without Supabase keys baked in, the submit-streak CTA + leaderboard tab are hidden.
        XCTAssertFalse(app.buttons["Submit streak to leaderboard"].exists)
    }
}
