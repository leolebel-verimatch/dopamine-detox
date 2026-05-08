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
        XCTAssertTrue(app.staticTexts["Dopamine Cap"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Choose distraction apps"].exists)
    }

    func testStartDayDisabledWithoutSelection() {
        let app = launchedApp()
        let startButton = app.buttons["Start day"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        XCTAssertFalse(startButton.isEnabled)
    }

    func testLeaderboardTabIsPresent() {
        let app = launchedApp()
        XCTAssertTrue(app.tabBars.buttons["Leaderboard"].waitForExistence(timeout: 5))
    }

    func testLeaderboardOpens() {
        let app = launchedApp()
        app.tabBars.buttons["Leaderboard"].tap()
        XCTAssertTrue(app.staticTexts["Leaderboard"].waitForExistence(timeout: 5))
    }
}
