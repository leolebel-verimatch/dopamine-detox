import XCTest
@testable import DopamineDetox

final class DayHistoryTests: XCTestCase {
    func testEmptyHistoryHasZeroStreak() {
        XCTAssertEqual(DayHistory().currentStreak, 0)
    }

    func testStreakCountsTrailingCleanDays() {
        let history = DayHistory(entries: [
            DayResult(day: "2026-04-30", shielded: true),
            DayResult(day: "2026-05-01", shielded: false),
            DayResult(day: "2026-05-02", shielded: false),
            DayResult(day: "2026-05-03", shielded: false)
        ])
        XCTAssertEqual(history.currentStreak, 3)
    }

    func testStreakResetsOnShieldedDay() {
        let history = DayHistory(entries: [
            DayResult(day: "2026-05-01", shielded: false),
            DayResult(day: "2026-05-02", shielded: false),
            DayResult(day: "2026-05-03", shielded: true)
        ])
        XCTAssertEqual(history.currentStreak, 0)
    }

    func testStreakResetsOnDisqualifiedDay() {
        let history = DayHistory(entries: [
            DayResult(day: "2026-05-01", shielded: false),
            DayResult(day: "2026-05-02", shielded: false, disqualified: true),
            DayResult(day: "2026-05-03", shielded: false)
        ])
        XCTAssertEqual(history.currentStreak, 1)
    }

    func testStreakIsZeroWhenLastDayIsShielded() {
        let history = DayHistory(entries: [
            DayResult(day: "2026-05-01", shielded: false),
            DayResult(day: "2026-05-02", shielded: true),
            DayResult(day: "2026-05-03", shielded: false)
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

    func testUpsertReplacesShieldAndPreservesMinutes() {
        var history = DayHistory()
        history.upsert(day: "2026-05-01", shielded: false, minutesUsed: 90, points: 30)
        history.upsert(day: "2026-05-01", shielded: true)
        let entry = history.entries.first!
        XCTAssertTrue(entry.shielded)
        XCTAssertEqual(entry.minutesUsed, 90)
        XCTAssertEqual(entry.points, 30)
    }

    func testTotalPointsSumsEntries() {
        let history = DayHistory(entries: [
            DayResult(day: "2026-05-01", shielded: false, points: 30),
            DayResult(day: "2026-05-02", shielded: false, points: 20),
            DayResult(day: "2026-05-03", shielded: true, points: 0)
        ])
        XCTAssertEqual(history.totalPoints, 50)
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

    func testScoringFormula() {
        XCTAssertEqual(Scoring.score(minutesUsed: 0, shielded: false), 120)
        XCTAssertEqual(Scoring.score(minutesUsed: 60, shielded: false), 60)
        XCTAssertEqual(Scoring.score(minutesUsed: 120, shielded: true), 0)
        // Hardcore bonus: shielded with >= 30 min runway before midnight.
        XCTAssertEqual(Scoring.score(minutesUsed: 120, shielded: true, shieldedMinutesBeforeMidnight: 30), 25)
    }
}
