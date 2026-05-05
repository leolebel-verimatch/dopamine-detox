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
        let updated_at: String?

        var id: String { user_id + day }
    }

    func upsertStreak(userId: String, score: Int, day: String) async throws {
        guard let client else { throw SupabaseError.notConfigured }
        let entry = ScoreEntry(
            user_id: userId,
            day: day,
            score: score,
            updated_at: nil
        )
        try await client
            .from("leaderboard")
            .upsert(entry, onConflict: "user_id,day")
            .execute()
    }

    func topStreaks(forDay day: String, limit: Int = 50) async throws -> [ScoreEntry] {
        guard let client else { throw SupabaseError.notConfigured }
        let response: [ScoreEntry] = try await client
            .from("leaderboard")
            .select("user_id,day,score,updated_at")
            .eq("day", value: day)
            .order("score", ascending: false)
            .limit(limit)
            .execute()
            .value
        return response
    }
}
