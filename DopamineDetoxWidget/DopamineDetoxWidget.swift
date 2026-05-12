import WidgetKit
import SwiftUI

struct LastScrollWidgetEntry: TimelineEntry {
    let date: Date
    let minutesUsed: Int
    let minutesCap: Int
    let streak: Int
    let rank: Int?
    let total: Int?
    let shielded: Bool
}

struct LastScrollProvider: TimelineProvider {
    func placeholder(in context: Context) -> LastScrollWidgetEntry {
        LastScrollWidgetEntry(date: .now, minutesUsed: 35, minutesCap: 120, streak: 4, rank: 12, total: 200, shielded: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (LastScrollWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LastScrollWidgetEntry>) -> Void) {
        let entry = currentEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> LastScrollWidgetEntry {
        let defaults = UserDefaults(suiteName: AppConstants.appGroup)
        let minutes = defaults?.integer(forKey: SharedKeys.minutesUsedToday) ?? 0
        let history = DayHistoryStore.load(from: defaults)
        let rank = defaults?.object(forKey: SharedKeys.cachedRank) as? Int
        let total = defaults?.object(forKey: SharedKeys.cachedTotal) as? Int
        let shielded = defaults?.bool(forKey: SharedKeys.shielded) ?? false
        return LastScrollWidgetEntry(
            date: .now,
            minutesUsed: minutes,
            minutesCap: AppConstants.dailyLimitMinutes,
            streak: history.currentStreak,
            rank: rank,
            total: total,
            shielded: shielded
        )
    }
}

struct LastScrollWidgetView: View {
    let entry: LastScrollWidgetEntry
    @Environment(\.widgetFamily) private var family

    private var remaining: Int { max(0, entry.minutesCap - entry.minutesUsed) }
    private var progress: Double { min(1, Double(entry.minutesUsed) / Double(entry.minutesCap)) }
    private var tint: Color {
        if entry.shielded { return Color(red: 0.95, green: 0.30, blue: 0.30) }
        if remaining < 15 { return Color(red: 0.98, green: 0.74, blue: 0.36) }
        return Color(red: 0.36, green: 0.94, blue: 0.51)
    }

    var body: some View {
        switch family {
        case .systemSmall: small
        default: medium
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Last Scroll")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.1), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: max(0.001, progress))
                        .stroke(tint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(remaining)")
                        .font(.system(.body, weight: .medium).monospacedDigit())
                        .foregroundStyle(.primary)
                }
                .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text("min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let rank = entry.rank, let total = entry.total {
                Text("Rank \(rank) of \(total)")
                    .font(.caption2)
                    .foregroundStyle(tint)
            } else {
                Text("\(entry.streak)-day streak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.1), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: max(0.001, progress))
                    .stroke(tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(remaining)")
                        .font(.system(.title3, weight: .medium).monospacedDigit())
                        .foregroundStyle(.primary)
                    Text("min left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 80, height: 80)
            VStack(alignment: .leading, spacing: 6) {
                Text("Last Scroll")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                if let rank = entry.rank, let total = entry.total {
                    Text("Rank \(rank) of \(total)")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(tint)
                    Text("school leaderboard")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(entry.streak)-day streak")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(tint)
                    Text("submit to enter the contest")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ProgressView(value: progress)
                    .tint(tint)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }
}

struct LastScrollWidget: Widget {
    let kind: String = "LastScrollWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LastScrollProvider()) { entry in
            LastScrollWidgetView(entry: entry)
                .containerBackground(Color(red: 0.02, green: 0.02, blue: 0.03), for: .widget)
        }
        .configurationDisplayName("Last Scroll")
        .description("Budget remaining + school rank.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct LastScrollWidgetBundle: WidgetBundle {
    var body: some Widget {
        LastScrollWidget()
    }
}
