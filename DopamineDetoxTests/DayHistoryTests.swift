import XCTest
@testable import DopamineDetox

final class DayHistoryTests: XCTestCase {
    func testEmptyHistoryHasZeroStreak() {
        XCTAssertEqual(DayHistory().currentStreak, 0)
    }

    func testStreakCountsTrailingCleanDays() {
        let history = DayHistory(entries: [
            .init(day: "2026-04-30", shielded: true),
            .init(day: "2026-05-01", shielded: false),
            .init(day: "2026-05-02", shielded: false),
            .init(day: "2026-05-03", shielded: false)
        ])
        XCTAssertEqual(history.currentStreak, 3)
    }

    func testStreakResetsOnShieldedDay() {
        let history = DayHistory(entries: [
            .init(day: "2026-05-01", shielded: false),
            .init(day: "2026-05-02", shielded: false),
            .init(day: "2026-05-03", shielded: true)
        ])
        XCTAssertEqual(history.currentStreak, 0)
    }

    func testStreakIsZeroWhenLastDayIsShielded() {
        let history = DayHistory(entries: [
            .init(day: "2026-05-01", shielded: false),
            .init(day: "2026-05-02", shielded: true),
            .init(day: "2026-05-03", shielded: false)
        ])
        XCTAssertEqual(history.currentStreak, 1)
    }

    func testRecordIfMissingIsIdempotent() {
        var history = DayHistory()
        history.recordIfMissing(day: "2026-05-01", shielded: false)
        history.recordIfMissing(day: "2026-05-01", shielded: true)
        XCTAssertEqual(history.entries.count, 1)
        XCTAssertEqual(history.entries.first?.shielded, false)
    }

    func testRecordSortsByDay() {
        var history = DayHistory()
        history.recordIfMissing(day: "2026-05-03", shielded: false)
        history.recordIfMissing(day: "2026-05-01", shielded: false)
        history.recordIfMissing(day: "2026-05-02", shielded: true)
        XCTAssertEqual(history.entries.map(\.day), ["2026-05-01", "2026-05-02", "2026-05-03"])
    }

    func testHasEntryDetectsExistingDay() {
        var history = DayHistory()
        history.recordIfMissing(day: "2026-05-01", shielded: false)
        XCTAssertTrue(history.hasEntry(for: "2026-05-01"))
        XCTAssertFalse(history.hasEntry(for: "2026-05-02"))
    }
}
