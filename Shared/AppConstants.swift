import Foundation

enum AppConstants {
    static let appGroup = "group.com.cheddarlebel.dopaminedetox"
    static let shieldStoreName = "DopamineDetoxShield"
    static let dailyLimitMinutes = 120
}

enum SharedKeys {
    static let selection = "selection"
    static let monitoringStartedAt = "monitoringStartedAt"
    static let shielded = "shielded"
    static let dayHistory = "dayHistory"
    static let userId = "userId"
    static let lastSubmittedDay = "lastSubmittedDay"
    static let lastSubmittedScore = "lastSubmittedScore"
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
