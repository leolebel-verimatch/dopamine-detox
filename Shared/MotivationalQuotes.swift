import Foundation

enum GradeLevel: String, CaseIterable, Codable, Identifiable {
    case middle = "Middle School"
    case nine = "Grade 9"
    case ten = "Grade 10"
    case eleven = "Grade 11"
    case twelve = "Grade 12"
    case college = "College"

    var id: String { rawValue }
}

enum MotivationalQuotes {
    static func quote(for grade: GradeLevel?, seed: Int = Calendar.current.component(.day, from: Date())) -> String {
        let pool: [String]
        switch grade ?? .eleven {
        case .middle:
            pool = [
                "The grades you build now decide what doors open in three years. Close the app.",
                "Streaks compound. Five clean days makes day six easier.",
                "Your future locker self thanks you. Get to homework.",
                "Champions don't make excuses at minute 121."
            ]
        case .nine:
            pool = [
                "GPA starts the day you stop scrolling. Today counts.",
                "Freshman year sets the ceiling. Raise it.",
                "Every minute back is a minute toward the team or club you actually want.",
                "Easy now, easy at 17. Hard now, easy at 22."
            ]
        case .ten:
            pool = [
                "PSAT season. Every reclaimed hour is one less weekend lost.",
                "AP teachers notice who shows up sharp. Be sharp.",
                "Your sophomore self is two grades away from college apps. Use the time.",
                "The kid who beat you this morning kept scrolling. Don't."
            ]
        case .eleven:
            pool = [
                "Junior year is the year that gets read. Make it count.",
                "Every hour back is one more SAT prep block, one more essay draft.",
                "The score you submit in October is the score college sees forever.",
                "Future you opening a college email is begging present you to focus."
            ]
        case .twelve:
            pool = [
                "Apps are in. Grades aren't locked. Stop scrolling, start finishing.",
                "Decision day is closer than you think. Senior slump is real and beatable.",
                "Last quarter GPA still matters for scholarships. Eyes up.",
                "You earned the offer. Don't lose it to a feed."
            ]
        case .college:
            pool = [
                "Tuition costs more per hour than your phone is worth. Close it.",
                "Grad school admits read GPA. Read your textbook.",
                "Internships open for students who finish strong.",
                "Your future starting salary is being decided in the next two hours."
            ]
        }
        return pool[abs(seed) % pool.count]
    }
}

enum GradeLevelStore {
    static func load(from defaults: UserDefaults?) -> GradeLevel? {
        guard let raw = defaults?.string(forKey: SharedKeys.gradeLevel) else { return nil }
        return GradeLevel(rawValue: raw)
    }

    static func save(_ grade: GradeLevel?, to defaults: UserDefaults?) {
        if let grade {
            defaults?.set(grade.rawValue, forKey: SharedKeys.gradeLevel)
        } else {
            defaults?.removeObject(forKey: SharedKeys.gradeLevel)
        }
    }
}
