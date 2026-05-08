import XCTest

/// Run with the `Screenshots` scheme on each App-Store-required simulator size.
/// `xcrun simctl io <sim> screenshot path.png` is alternative for grabbing the raw simulator
/// frame, but XCTAttachment captures via the test runner, which is what the App Store Fastlane
/// flow expects. Output is in the .xcresult bundle.
final class ScreenshotTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    private func launchedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-hasOnboarded", "YES"]
        app.launch()
        return app
    }

    private func snapshot(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCaptureControlCenterIdle() {
        let app = launchedApp()
        XCTAssertTrue(app.staticTexts["Last Scroll"].waitForExistence(timeout: 5))
        snapshot(app, named: "01-control-center-idle")
    }

    func testCaptureLeaderboard() {
        let app = launchedApp()
        XCTAssertTrue(app.tabBars.buttons["Leaderboard"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Leaderboard"].tap()
        XCTAssertTrue(app.staticTexts["Leaderboard"].waitForExistence(timeout: 5))
        snapshot(app, named: "02-leaderboard")
    }

    func testCaptureOnboarding() {
        let app = XCUIApplication()
        app.launchArguments += ["-hasOnboarded", "NO"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Cap the feeds"].waitForExistence(timeout: 5))
        snapshot(app, named: "03-onboarding-1")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Build a streak"].waitForExistence(timeout: 5))
        snapshot(app, named: "04-onboarding-2")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["No easy outs"].waitForExistence(timeout: 5))
        snapshot(app, named: "05-onboarding-3")
    }
}
