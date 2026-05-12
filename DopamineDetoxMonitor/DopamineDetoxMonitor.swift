import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

final class DopamineDetoxMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: .init(rawValue: AppConstants.shieldStoreName))
    private let pomodoroStore = ManagedSettingsStore(named: .init(rawValue: AppConstants.pomodoroShieldStoreName))
    private let defaults = UserDefaults(suiteName: AppConstants.appGroup)

    private var isPomodoro: (DeviceActivityName) -> Bool {
        { $0.rawValue == "DopamineDetox.Pomodoro" }
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        if isPomodoro(activity) { return }
        defaults?.set(Date(), forKey: SharedKeys.monitoringStartedAt)
        defaults?.set(false, forKey: SharedKeys.shielded)
        defaults?.set(0, forKey: SharedKeys.minutesUsedToday)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        if isPomodoro(activity) {
            // Deep Work session ended — clear the dedicated Pomodoro store and the
            // app-side flag. Daily monitoring is unaffected.
            pomodoroStore.shield.applications = nil
            pomodoroStore.shield.applicationCategories = nil
            pomodoroStore.shield.webDomains = nil
            defaults?.set(false, forKey: SharedKeys.pomodoroActive)
            defaults?.removeObject(forKey: SharedKeys.pomodoroEndsAt)
            return
        }
        let wasShielded = defaults?.bool(forKey: SharedKeys.shielded) ?? false
        let minutes = defaults?.integer(forKey: SharedKeys.minutesUsedToday) ?? 0
        let day = ISO8601Day.todayString()
        let dq = defaults?.bool(forKey: SharedKeys.disqualified) ?? false
        let points = dq ? 0 : Scoring.score(minutesUsed: minutes, shielded: wasShielded)
        var history = DayHistoryStore.load(from: defaults)
        history.recordIfMissing(day: day, shielded: wasShielded, minutesUsed: minutes, points: points, disqualified: dq ? true : nil)
        DayHistoryStore.save(history, to: defaults)

        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        defaults?.set(false, forKey: SharedKeys.shielded)
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        switch event.rawValue {
        case "DopamineDetox.LimitReached":
            applyShield()
        case "DopamineDetox.WarningThreshold":
            let warningMinutes = Int(Double(AppConstants.dailyLimitMinutes) * 0.9)
            defaults?.set(warningMinutes, forKey: SharedKeys.minutesUsedToday)
        default:
            break
        }
    }

    private func applyShield() {
        guard let data = defaults?.data(forKey: SharedKeys.selection),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return
        }
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        defaults?.set(true, forKey: SharedKeys.shielded)
        defaults?.set(Date(), forKey: SharedKeys.shieldedAt)
        defaults?.set(AppConstants.dailyLimitMinutes, forKey: SharedKeys.minutesUsedToday)
    }
}
