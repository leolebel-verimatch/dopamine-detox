import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings
import UIKit

@MainActor
final class ScreenTimeManager: ObservableObject {
    enum AuthState { case notDetermined, authorized, denied }

    @Published var authState: AuthState = .notDetermined
    @Published var selection: FamilyActivitySelection
    @Published var monitoringStartedAt: Date?
    @Published var shielded: Bool = false
    @Published var history: DayHistory

    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore(named: .init(rawValue: AppConstants.shieldStoreName))
    private let defaults = UserDefaults(suiteName: AppConstants.appGroup)

    static let activityName = DeviceActivityName(rawValue: "DopamineDetox.Daily")
    static let eventName = DeviceActivityEvent.Name(rawValue: "DopamineDetox.LimitReached")

    init() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroup)
        if let data = defaults?.data(forKey: SharedKeys.selection),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = decoded
        } else {
            selection = FamilyActivitySelection()
        }
        history = DayHistoryStore.load(from: defaults)
        refreshState()
        resolveYesterdayIfNeeded()
        syncAuthorizationStatus()
    }

    var hasAppsSelected: Bool {
        !selection.applicationTokens.isEmpty ||
        !selection.categoryTokens.isEmpty ||
        !selection.webDomainTokens.isEmpty
    }

    var stableUserId: String {
        if let existing = defaults?.string(forKey: SharedKeys.userId) { return existing }
        let new = UUID().uuidString
        defaults?.set(new, forKey: SharedKeys.userId)
        return new
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            // Fall through to status read.
        }
        syncAuthorizationStatus()
    }

    func syncAuthorizationStatus() {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved: authState = .authorized
        case .denied: authState = .denied
        default: authState = .notDetermined
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func saveSelection(_ new: FamilyActivitySelection) {
        selection = new
        if let encoded = try? JSONEncoder().encode(new) {
            defaults?.set(encoded, forKey: SharedKeys.selection)
        }
    }

    func startMonitoring() throws {
        guard hasAppsSelected else { return }
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: AppConstants.dailyLimitMinutes)
        )
        center.stopMonitoring([Self.activityName])
        try center.startMonitoring(
            Self.activityName,
            during: schedule,
            events: [Self.eventName: event]
        )
        let now = Date()
        defaults?.set(now, forKey: SharedKeys.monitoringStartedAt)
        defaults?.set(false, forKey: SharedKeys.shielded)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
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
        monitoringStartedAt = defaults?.object(forKey: SharedKeys.monitoringStartedAt) as? Date
        shielded = defaults?.bool(forKey: SharedKeys.shielded) ?? false
        history = DayHistoryStore.load(from: defaults)
    }

    /// On every app foreground, finalize any past completed days that haven't been recorded.
    /// A day counts as "shielded" if the shield was triggered before midnight; otherwise the
    /// streak survives.
    func resolveYesterdayIfNeeded(now: Date = Date(), calendar: Calendar = .current) {
        let today = ISO8601Day.string(from: calendar.startOfDay(for: now))
        let startedAtDay: String? = (defaults?.object(forKey: SharedKeys.monitoringStartedAt) as? Date)
            .map { ISO8601Day.string(from: calendar.startOfDay(for: $0)) }
        let currentlyShielded = defaults?.bool(forKey: SharedKeys.shielded) ?? false

        guard let startDay = startedAtDay, startDay < today else { return }

        var working = DayHistoryStore.load(from: defaults)
        // Only the start day's outcome is known to us; we record it once and clear shielded
        // state so a fresh day starts clean.
        working.recordIfMissing(day: startDay, shielded: currentlyShielded)
        DayHistoryStore.save(working, to: defaults)
        history = working

        // Reset the day for today.
        defaults?.set(false, forKey: SharedKeys.shielded)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        shielded = false
    }
}
