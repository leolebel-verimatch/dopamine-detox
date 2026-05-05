import Foundation

enum UnlockChallenge {
    static let phrase = "I am the architect of my attention and every minute I reclaim from the feed compounds into a life I am proud of"

    static func matches(_ input: String) -> Bool {
        input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            == phrase.lowercased()
    }
}
