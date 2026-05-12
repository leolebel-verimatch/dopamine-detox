import Foundation

struct DayResult: Codable, Equatable {
    let day: String
    let shielded: Bool
    var minutesUsed: Int?
    var points: Int?
    var disqualified: Bool?

    init(day: String, shielded: Bool, minutesUsed: Int? = nil, points: Int? = nil, disqualified: Bool? = nil) {
        self.day = day
        self.shielded = shielded
        self.minutesUsed = minutesUsed
        self.points = points
        self.disqualified = disqualified
    }
}

struct DayHistory: Codable, Equatable {
    var entries: [DayResult] = []

    /// Streak grows for every clean (non-shielded, non-DQ) day. Resets on shield or DQ.
    var currentStreak: Int {
        var streak = 0
        for entry in entries.reversed() {
            if entry.shielded { break }
            if entry.disqualified == true { break }
            streak += 1
        }
        return streak
    }

    var totalPoints: Int {
        entries.reduce(0) { $0 + ($1.points ?? 0) }
    }

    func hasEntry(for day: String) -> Bool {
        entries.contains { $0.day == day }
    }

    mutating func recordIfMissing(day: String, shielded: Bool, minutesUsed: Int? = nil, points: Int? = nil, disqualified: Bool? = nil) {
        guard !hasEntry(for: day) else { return }
        entries.append(DayResult(day: day, shielded: shielded, minutesUsed: minutesUsed, points: points, disqualified: disqualified))
        entries.sort { $0.day < $1.day }
    }

    mutating func upsert(day: String, shielded: Bool, minutesUsed: Int? = nil, points: Int? = nil, disqualified: Bool? = nil) {
        if let idx = entries.firstIndex(where: { $0.day == day }) {
            var existing = entries[idx]
            existing = DayResult(
                day: day,
                shielded: shielded,
                minutesUsed: minutesUsed ?? existing.minutesUsed,
                points: points ?? existing.points,
                disqualified: disqualified ?? existing.disqualified
            )
            entries[idx] = existing
        } else {
            entries.append(DayResult(day: day, shielded: shielded, minutesUsed: minutesUsed, points: points, disqualified: disqualified))
            entries.sort { $0.day < $1.day }
        }
    }
}

enum DayHistoryStore {
    static func load(from defaults: UserDefaults?) -> DayHistory {
        guard let data = defaults?.data(forKey: SharedKeys.dayHistory),
              let history = try? JSONDecoder().decode(DayHistory.self, from: data)
        else { return DayHistory() }
        return history
    }

    static func save(_ history: DayHistory, to defaults: UserDefaults?) {
        guard let data = try? JSONEncoder().encode(history) else { return }
        defaults?.set(data, forKey: SharedKeys.dayHistory)
    }
}
