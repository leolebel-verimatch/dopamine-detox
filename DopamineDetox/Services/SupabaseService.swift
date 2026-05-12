import Foundation
import Supabase

enum SupabaseError: Error {
    case notConfigured
}

final class SupabaseService {
    static let shared = SupabaseService()

    private let client: SupabaseClient?

    private init() {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            !urlString.contains("YOUR_PROJECT"),
            !key.contains("REPLACE_ME"),
            let url = URL(string: urlString)
        else {
            client = nil
            return
        }
        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }

    var isConfigured: Bool { client != nil }

    struct ScoreEntry: Codable, Hashable, Identifiable {
        let user_id: String
        let day: String
        let score: Int
        let minutes_used: Int?
        let disqualified: Bool?
        let updated_at: String?

        var id: String { user_id + day }
    }

    private struct StatusPayload: Encodable {
        let user_id: String
        let day: String
        let score: Int
        let minutes_used: Int
        let shielded: Bool
        let disqualified: Bool
        let disqualification_reason: String?
    }

    func upsertStreak(userId: String, score: Int, day: String, minutesUsed: Int, shielded: Bool) async throws {
        guard let client else { throw SupabaseError.notConfigured }
        let entry = StatusPayload(
            user_id: userId,
            day: day,
            score: score,
            minutes_used: minutesUsed,
            shielded: shielded,
            disqualified: false,
            disqualification_reason: nil
        )
        try await client
            .from("leaderboard")
            .upsert(entry, onConflict: "user_id,day")
            .execute()
    }

    func reportStatus(userId: String, day: String, disqualified: Bool, disqualificationReason: String?, minutesUsed: Int, shielded: Bool) async throws {
        guard let client else { throw SupabaseError.notConfigured }
        let score = disqualified ? 0 : Scoring.score(minutesUsed: minutesUsed, shielded: shielded)
        let entry = StatusPayload(
            user_id: userId,
            day: day,
            score: score,
            minutes_used: minutesUsed,
            shielded: shielded,
            disqualified: disqualified,
            disqualification_reason: disqualificationReason
        )
        try await client
            .from("leaderboard")
            .upsert(entry, onConflict: "user_id,day")
            .execute()
    }

    /// Returns (rank, totalParticipants) for a given user on a given day. Rank counts only
    /// non-disqualified entries with strictly higher scores; ties share the same rank.
    func rank(userId: String, day: String) async throws -> (Int, Int)? {
        guard let client else { throw SupabaseError.notConfigured }
        let entries: [ScoreEntry] = try await client
            .from("leaderboard")
            .select("user_id,day,score,minutes_used,disqualified,updated_at")
            .eq("day", value: day)
            .eq("disqualified", value: false)
            .order("score", ascending: false)
            .execute()
            .value
        guard let myScore = entries.first(where: { $0.user_id == userId })?.score else {
            return nil
        }
        let ahead = entries.filter { $0.score > myScore }.count
        return (ahead + 1, entries.count)
    }

    func topStreaks(forDay day: String, limit: Int = 50) async throws -> [ScoreEntry] {
        guard let client else { throw SupabaseError.notConfigured }
        let response: [ScoreEntry] = try await client
            .from("leaderboard")
            .select("user_id,day,score,minutes_used,disqualified,updated_at")
            .eq("day", value: day)
            .eq("disqualified", value: false)
            .order("score", ascending: false)
            .limit(limit)
            .execute()
            .value
        return response
    }
}
