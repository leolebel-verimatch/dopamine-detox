import Foundation

enum AppConstants {
    static let appGroup = "group.com.cheddarlebel.dopaminedetox"
    static let shieldStoreName = "DopamineDetoxShield"
    static let pomodoroShieldStoreName = "DopamineDetoxPomodoro"
    static let dailyLimitMinutes = 120
    static let pomodoroMinutes = 25
    static let autoSyncHour = 21
    static let hardcoreShieldStreakMinutes = 30
}

enum SharedKeys {
    static let selection = "selection"
    static let productivePass = "productivePass"
    static let monitoringStartedAt = "monitoringStartedAt"
    static let shielded = "shielded"
    static let shieldedAt = "shieldedAt"
    static let pomodoroEndsAt = "pomodoroEndsAt"
    static let pomodoroActive = "pomodoroActive"
    static let dayHistory = "dayHistory"
    static let userId = "userId"
    static let lastSubmittedDay = "lastSubmittedDay"
    static let lastSubmittedScore = "lastSubmittedScore"
    static let disqualified = "disqualified"
    static let minutesUsedToday = "minutesUsedToday"
    static let gradeLevel = "gradeLevel"
    static let cachedRank = "cachedRank"
    static let cachedTotal = "cachedTotal"
    static let heartbeatFiredForDay = "heartbeatFiredForDay"
}

enum ISO8601Day {
    static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()

    static func string(from date: Date) -> String { formatter.string(from: date) }

    static func startOfDay(_ date: Date, in calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func todayString(calendar: Calendar = .current, now: Date = Date()) -> String {
        string(from: startOfDay(now, in: calendar))
    }
}

enum Scoring {
    /// FR-03: points = max(0, 120 - minutesUsed). Awards a Hardcore Streak bonus if the
    /// student was shielded with more than `hardcoreShieldStreakMinutes` left in the day.
    static func score(minutesUsed: Int, shielded: Bool, shieldedMinutesBeforeMidnight: Int = 0) -> Int {
        let base = max(0, AppConstants.dailyLimitMinutes - minutesUsed)
        let bonus = (shielded && shieldedMinutesBeforeMidnight >= AppConstants.hardcoreShieldStreakMinutes) ? 25 : 0
        return base + bonus
    }
}

enum DayResultStatus: String, Codable {
    case clean
    case shielded
    case disqualified
}
