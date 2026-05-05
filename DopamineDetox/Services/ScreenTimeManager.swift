import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

@MainActor
final class ScreenTimeManager: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var selection: FamilyActivitySelection
    @Published var monitoringStartedAt: Date?
    @Published var shielded: Bool = false

    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore(named: .init(rawValue: Theme.shieldStoreName))
    private let defaults = UserDefaults(suiteName: Theme.appGroup)

    static let activityName = DeviceActivityName(rawValue: "DopamineDetox.Daily")
    static let eventName = DeviceActivityEvent.Name(rawValue: "DopamineDetox.LimitReached")

    init() {
        if let data = defaults?.data(forKey: SharedKeys.selection),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = decoded
        } else {
            selection = FamilyActivitySelection()
        }
        refreshState()
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        } catch {
            isAuthorized = false
        }
    }

    func saveSelection(_ new: FamilyActivitySelection) {
        selection = new
        if let encoded = try? JSONEncoder().encode(new) {
            defaults?.set(encoded, forKey: SharedKeys.selection)
        }
    }

    func startMonitoring() throws {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: Theme.dailyLimitMinutes)
        )
        center.stopMonitoring([Self.activityName])
        try center.startMonitoring(
            Self.activityName,
            during: schedule,
            events: [Self.eventName: event]
        )
        let now = Date()
        defaults?.set(now, forKey: SharedKeys.startedAt)
        defaults?.set(false, forKey: SharedKeys.shielded)
        monitoringStartedAt = now
        shielded = false
    }

    func liftShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        defaults?.set(false, forKey: SharedKeys.shielded)
        shielded = false
    }

    func refreshState() {
        monitoringStartedAt = defaults?.object(forKey: SharedKeys.startedAt) as? Date
        shielded = defaults?.bool(forKey: SharedKeys.shielded) ?? false
    }
}

enum SharedKeys {
    static let selection = "selection"
    static let startedAt = "monitoringStartedAt"
    static let shielded = "shielded"
}
