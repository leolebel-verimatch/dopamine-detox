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
    @Published var productivePass: FamilyActivitySelection
    @Published var monitoringStartedAt: Date?
    @Published var shielded: Bool = false
    @Published var pomodoroActive: Bool = false
    @Published var pomodoroEndsAt: Date?
    @Published var history: DayHistory
    @Published var disqualified: Bool = false

    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore(named: .init(rawValue: AppConstants.shieldStoreName))
    private let pomodoroStore = ManagedSettingsStore(named: .init(rawValue: AppConstants.pomodoroShieldStoreName))
    private let defaults = UserDefaults(suiteName: AppConstants.appGroup)

    static let activityName = DeviceActivityName(rawValue: "DopamineDetox.Daily")
    static let limitEventName = DeviceActivityEvent.Name(rawValue: "DopamineDetox.LimitReached")
    static let warningEventName = DeviceActivityEvent.Name(rawValue: "DopamineDetox.WarningThreshold")
    static let pomodoroActivityName = DeviceActivityName(rawValue: "DopamineDetox.Pomodoro")

    init() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroup)
        if let data = defaults?.data(forKey: SharedKeys.selection),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = decoded
        } else {
            selection = FamilyActivitySelection()
        }
        if let data = defaults?.data(forKey: SharedKeys.productivePass),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            productivePass = decoded
        } else {
            productivePass = FamilyActivitySelection()
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

    var minutesUsedToday: Int {
        defaults?.integer(forKey: SharedKeys.minutesUsedToday) ?? 0
    }

    var remainingMinutes: Int {
        max(0, AppConstants.dailyLimitMinutes - minutesUsedToday)
    }

    var todayScore: Int {
        Scoring.score(minutesUsed: minutesUsedToday, shielded: shielded)
    }

    var grade: GradeLevel? {
        get { GradeLevelStore.load(from: defaults) }
        set { GradeLevelStore.save(newValue, to: defaults) }
    }

    /// Fires once per day when usage crosses 90% of the budget. Idempotent.
    func fireHeartbeatIfNeeded() {
        let threshold = Int(Double(AppConstants.dailyLimitMinutes) * 0.9)
        guard minutesUsedToday >= threshold else { return }
        let today = ISO8601Day.todayString()
        if defaults?.string(forKey: SharedKeys.heartbeatFiredForDay) == today { return }
        defaults?.set(today, forKey: SharedKeys.heartbeatFiredForDay)
        Task { @MainActor in Haptics.heartbeat() }
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
        let previous = authState
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved: authState = .authorized
        case .denied: authState = .denied
        default: authState = .notDetermined
        }
        // FR-X-Factor: if authorization is revoked while monitoring is active, flag DQ.
        if previous == .authorized && authState != .authorized && monitoringStartedAt != nil {
            flagDisqualified(reason: "auth_revoked")
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

    func saveProductivePass(_ new: FamilyActivitySelection) {
        productivePass = new
        if let encoded = try? JSONEncoder().encode(new) {
            defaults?.set(encoded, forKey: SharedKeys.productivePass)
        }
    }

    func startMonitoring() throws {
        guard hasAppsSelected else { return }
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let limitEvent = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: AppConstants.dailyLimitMinutes)
        )
        let warningMinutes = Int(Double(AppConstants.dailyLimitMinutes) * 0.9)
        let warningEvent = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: warningMinutes)
        )
        // FR-03 evening auto-sync is gated by the host-app hour check in ControlCenterView
        // (`autoSubmitIfDue` requires `hour >= 21`). No DeviceActivityEvent is needed —
        // a usage-threshold event can only fire on usage, not on wall-clock time.
        center.stopMonitoring([Self.activityName])
        try center.startMonitoring(
            Self.activityName,
            during: schedule,
            events: [
                Self.limitEventName: limitEvent,
                Self.warningEventName: warningEvent
            ]
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

    /// FR-04: Deep Work Pomodoro — manual 25-min shield on the same selected apps.
    /// If the 25-min window would cross midnight, the end is clamped to 23:59 so the
    /// DeviceActivitySchedule doesn't wrap (DateComponents h/m/s alone has no day).
    func startPomodoro() throws {
        guard hasAppsSelected else { return }
        let calendar = Calendar.current
        let now = Date()
        let naturalEnd = calendar.date(byAdding: .minute, value: AppConstants.pomodoroMinutes, to: now) ?? now
        let startOfTomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        let crossesMidnight = naturalEnd >= startOfTomorrow
        let end: Date
        if crossesMidnight {
            // 23:59:30 of today — gives the user a meaningful focus block without wrapping.
            end = calendar.date(bySettingHour: 23, minute: 59, second: 30, of: now) ?? naturalEnd
        } else {
            end = naturalEnd
        }
        let startComps = calendar.dateComponents([.hour, .minute, .second], from: now)
        let endComps = calendar.dateComponents([.hour, .minute, .second], from: end)
        let schedule = DeviceActivitySchedule(intervalStart: startComps, intervalEnd: endComps, repeats: false)
        center.stopMonitoring([Self.pomodoroActivityName])
        try center.startMonitoring(Self.pomodoroActivityName, during: schedule)
        pomodoroStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        if !selection.categoryTokens.isEmpty {
            pomodoroStore.shield.applicationCategories = .specific(selection.categoryTokens)
        }
        pomodoroStore.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        defaults?.set(end, forKey: SharedKeys.pomodoroEndsAt)
        defaults?.set(true, forKey: SharedKeys.pomodoroActive)
        pomodoroActive = true
        pomodoroEndsAt = end
    }

    func cancelPomodoro() {
        center.stopMonitoring([Self.pomodoroActivityName])
        pomodoroStore.shield.applications = nil
        pomodoroStore.shield.applicationCategories = nil
        pomodoroStore.shield.webDomains = nil
        defaults?.set(false, forKey: SharedKeys.pomodoroActive)
        defaults?.removeObject(forKey: SharedKeys.pomodoroEndsAt)
        pomodoroActive = false
        pomodoroEndsAt = nil
    }

    func refreshState() {
        monitoringStartedAt = defaults?.object(forKey: SharedKeys.monitoringStartedAt) as? Date
        shielded = defaults?.bool(forKey: SharedKeys.shielded) ?? false
        history = DayHistoryStore.load(from: defaults)
        disqualified = defaults?.bool(forKey: SharedKeys.disqualified) ?? false
        let active = defaults?.bool(forKey: SharedKeys.pomodoroActive) ?? false
        let endsAt = defaults?.object(forKey: SharedKeys.pomodoroEndsAt) as? Date
        if active, let ends = endsAt, ends > Date() {
            pomodoroActive = true
            pomodoroEndsAt = ends
        } else if active {
            // Pomodoro window expired while we were closed — clean up.
            cancelPomodoro()
        } else {
            pomodoroActive = false
            pomodoroEndsAt = nil
        }
    }

    func resolveYesterdayIfNeeded(now: Date = Date(), calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        guard let startedAt = defaults?.object(forKey: SharedKeys.monitoringStartedAt) as? Date else { return }
        let startDay = calendar.startOfDay(for: startedAt)
        guard startDay < today else { return }
        let currentlyShielded = defaults?.bool(forKey: SharedKeys.shielded) ?? false
        let minutesUsed = defaults?.integer(forKey: SharedKeys.minutesUsedToday) ?? 0

        var working = DayHistoryStore.load(from: defaults)
        var cursor = startDay
        var firstDay = true
        while cursor < today {
            let dayString = ISO8601Day.string(from: cursor)
            let outcome = firstDay ? currentlyShielded : false
            let minutes = firstDay ? minutesUsed : 0
            let pts = Scoring.score(minutesUsed: minutes, shielded: outcome)
            working.recordIfMissing(day: dayString, shielded: outcome, minutesUsed: minutes, points: pts)
            firstDay = false
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        DayHistoryStore.save(working, to: defaults)
        history = working

        defaults?.set(today, forKey: SharedKeys.monitoringStartedAt)
        defaults?.set(false, forKey: SharedKeys.shielded)
        defaults?.set(0, forKey: SharedKeys.minutesUsedToday)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        monitoringStartedAt = today
        shielded = false
    }

    func flagDisqualified(reason: String) {
        defaults?.set(true, forKey: SharedKeys.disqualified)
        disqualified = true
        let today = ISO8601Day.todayString()
        var working = DayHistoryStore.load(from: defaults)
        working.upsert(day: today, shielded: true, disqualified: true)
        DayHistoryStore.save(working, to: defaults)
        history = working
        Task { try? await SupabaseService.shared.reportStatus(
            userId: stableUserId,
            day: today,
            disqualified: true,
            disqualificationReason: reason,
            minutesUsed: minutesUsedToday,
            shielded: shielded
        ) }
    }

    /// Sends a heartbeat so the server can flag DQ if a device goes silent without explanation.
    func sendHeartbeat() {
        let day = ISO8601Day.todayString()
        Task {
            try? await SupabaseService.shared.reportStatus(
                userId: stableUserId,
                day: day,
                disqualified: disqualified,
                disqualificationReason: nil,
                minutesUsed: minutesUsedToday,
                shielded: shielded
            )
            await refreshRank(day: day)
        }
    }

    func refreshRank(day: String) async {
        guard SupabaseService.shared.isConfigured else { return }
        if let (rank, total) = try? await SupabaseService.shared.rank(userId: stableUserId, day: day) {
            defaults?.set(rank, forKey: SharedKeys.cachedRank)
            defaults?.set(total, forKey: SharedKeys.cachedTotal)
        }
    }
}
