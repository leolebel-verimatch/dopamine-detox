import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()

    private let client: SupabaseClient

    private init() {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
            ?? "https://YOUR_PROJECT.supabase.co"
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
            ?? "REPLACE_ME"
        let url = URL(string: urlString) ?? URL(string: "https://YOUR_PROJECT.supabase.co")!
        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }

    struct DailyScore: Encodable {
        let user_id: String
        let day: String
        let score: Int
    }

    func postDailyScore(userId: String, score: Int) async throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let entry = DailyScore(
            user_id: userId,
            day: formatter.string(from: Date()),
            score: score
        )
        try await client
            .from("leaderboard")
            .insert(entry)
            .execute()
    }
}
