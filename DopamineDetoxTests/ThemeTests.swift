import XCTest
@testable import DopamineDetox

final class AppConstantsTests: XCTestCase {
    func testDailyLimitIs120Minutes() {
        XCTAssertEqual(AppConstants.dailyLimitMinutes, 120)
    }

    func testAppGroupMatchesEntitlements() {
        XCTAssertEqual(AppConstants.appGroup, "group.com.cheddarlebel.dopaminedetox")
    }

    func testShieldStoreNameIsStable() {
        XCTAssertEqual(AppConstants.shieldStoreName, "DopamineDetoxShield")
    }
}
