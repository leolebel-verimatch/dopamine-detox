import XCTest

final class ControlCenterUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testLaunchAndShowsControlCenter() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Dopamine Detox"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["minutes left"].exists)
        XCTAssertTrue(app.buttons["Choose distraction apps"].exists)
    }

    func testStartDayDisabledWithoutSelection() {
        let app = XCUIApplication()
        app.launch()

        let startButton = app.buttons["Start day"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        XCTAssertFalse(startButton.isEnabled)
    }

    func testNoAppsSelectedWarningVisible() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["No distraction apps selected"].waitForExistence(timeout: 5))
    }
}
