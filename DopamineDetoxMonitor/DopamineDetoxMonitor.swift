import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

final class DopamineDetoxMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: .init(rawValue: "DopamineDetoxShield"))
    private let defaults = UserDefaults(suiteName: "group.com.cheddarlebel.dopaminedetox")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        defaults?.set(Date(), forKey: "monitoringStartedAt")
        defaults?.set(false, forKey: "shielded")
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        defaults?.set(false, forKey: "shielded")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard let data = defaults?.data(forKey: "selection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return
        }
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        defaults?.set(true, forKey: "shielded")
    }
}
