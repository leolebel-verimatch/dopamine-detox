import SwiftUI

@MainActor
final class LeaderboardModel: ObservableObject {
    enum State: Equatable {
        case loading
        case ready([SupabaseService.ScoreEntry])
        case empty
        case unconfigured
        case error(String)
    }

    @Published var state: State = .loading

    func load(today: String) async {
        guard SupabaseService.shared.isConfigured else {
            state = .unconfigured
            return
        }
        state = .loading
        do {
            let entries = try await SupabaseService.shared.topStreaks(forDay: today)
            state = entries.isEmpty ? .empty : .ready(entries)
        } catch {
            state = .error("Couldn't load leaderboard")
        }
    }
}

struct LeaderboardView: View {
    @EnvironmentObject var screenTime: ScreenTimeManager
    @StateObject private var model = LeaderboardModel()

    private var today: String { ISO8601Day.todayString() }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header
                Divider().background(Theme.surface)
                content
            }
        }
        .task { await model.load(today: today) }
        .refreshable { await model.load(today: today) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Leaderboard")
                .font(.system(.title3, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            Text("Today · longest streaks")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            VStack {
                Spacer()
                ProgressView().tint(Theme.textSecondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        case .empty:
            empty(text: "No scores yet today. Be first.")
        case .unconfigured:
            empty(text: "Leaderboard not configured. Add Supabase keys to enable.")
        case .error(let message):
            empty(text: message)
        case .ready(let entries):
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                        row(rank: idx + 1, entry: entry)
                        Divider().background(Theme.surface)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private func row(rank: Int, entry: SupabaseService.ScoreEntry) -> some View {
        let isMe = entry.user_id == screenTime.stableUserId
        return HStack(spacing: 16) {
            Text("\(rank)")
                .font(.callout.monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 32, alignment: .trailing)
            VStack(alignment: .leading, spacing: 2) {
                Text(isMe ? "You" : maskedId(entry.user_id))
                    .font(.callout)
                    .foregroundStyle(isMe ? Theme.accent : Theme.textPrimary)
                Text("\(entry.score) day\(entry.score == 1 ? "" : "s") clean")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text("\(entry.score)")
                .font(.system(.title3, weight: .light).monospacedDigit())
                .foregroundStyle(isMe ? Theme.accent : Theme.textPrimary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(isMe ? Theme.surface : Color.clear)
    }

    private func maskedId(_ id: String) -> String {
        let suffix = id.suffix(4)
        return "Anon · \(suffix)"
    }

    private func empty(text: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Text(text)
                .font(.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
