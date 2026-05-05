import XCTest
@testable import DopamineDetox

final class ThemeTests: XCTestCase {
    func testDailyLimitIs120Minutes() {
        XCTAssertEqual(Theme.dailyLimitMinutes, 120)
    }

    func testAppGroupMatchesEntitlements() {
        XCTAssertEqual(Theme.appGroup, "group.com.cheddarlebel.dopaminedetox")
    }
}
