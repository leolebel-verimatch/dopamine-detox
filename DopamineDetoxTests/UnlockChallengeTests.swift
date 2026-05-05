import XCTest
@testable import DopamineDetox

final class UnlockChallengeTests: XCTestCase {
    func testExactMatch() {
        XCTAssertTrue(UnlockChallenge.matches(UnlockChallenge.phrase))
    }

    func testTrimsWhitespaceAndNewlines() {
        let padded = "   \n\(UnlockChallenge.phrase)\n\n  "
        XCTAssertTrue(UnlockChallenge.matches(padded))
    }

    func testCaseInsensitive() {
        XCTAssertTrue(UnlockChallenge.matches(UnlockChallenge.phrase.uppercased()))
    }

    func testRejectsPartial() {
        let prefix = String(UnlockChallenge.phrase.prefix(20))
        XCTAssertFalse(UnlockChallenge.matches(prefix))
    }

    func testRejectsEmpty() {
        XCTAssertFalse(UnlockChallenge.matches(""))
    }

    func testRejectsTypo() {
        let withTypo = UnlockChallenge.phrase.replacingOccurrences(of: "architect", with: "architct")
        XCTAssertFalse(UnlockChallenge.matches(withTypo))
    }

    func testPhraseIsLong() {
        let words = UnlockChallenge.phrase.split(separator: " ")
        XCTAssertGreaterThanOrEqual(words.count, 20, "Phrase should be long enough to deter casual cheating")
    }
}
