import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

final class DopamineDetoxMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: .init(rawValue: AppConstants.shieldStoreName))
    private let defaults = UserDefaults(suiteName: AppConstants.appGroup)

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        defaults?.set(Date(), forKey: SharedKeys.monitoringStartedAt)
        defaults?.set(false, forKey: SharedKeys.shielded)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        let wasShielded = defaults?.bool(forKey: SharedKeys.shielded) ?? false
        let day = ISO8601Day.todayString()
        var history = DayHistoryStore.load(from: defaults)
        history.recordIfMissing(day: day, shielded: wasShielded)
        DayHistoryStore.save(history, to: defaults)

        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        defaults?.set(false, forKey: SharedKeys.shielded)
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
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
    }
}
