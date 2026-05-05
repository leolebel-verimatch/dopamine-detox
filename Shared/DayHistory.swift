import Foundation

struct DayResult: Codable, Equatable {
    let day: String
    let shielded: Bool
}

struct DayHistory: Codable, Equatable {
    var entries: [DayResult] = []

    var currentStreak: Int {
        var streak = 0
        for entry in entries.reversed() {
            if entry.shielded { break }
            streak += 1
        }
        return streak
    }

    func hasEntry(for day: String) -> Bool {
        entries.contains { $0.day == day }
    }

    mutating func recordIfMissing(day: String, shielded: Bool) {
        guard !hasEntry(for: day) else { return }
        entries.append(DayResult(day: day, shielded: shielded))
        entries.sort { $0.day < $1.day }
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
