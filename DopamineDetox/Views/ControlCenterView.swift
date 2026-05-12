import SwiftUI

struct ControlCenterView: View {
    @EnvironmentObject var screenTime: ScreenTimeManager
    @State private var showingPicker = false
    @State private var showingProductivePass = false
    @State private var showingUnlock = false
    @State private var showingSettings = false
    @State private var submitting = false
    @State private var submitMessage: String?
    @State private var lastSubmittedDay: String?
    @State private var now: Date = .now

    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    private var streak: Int { screenTime.history.currentStreak }

    private enum Status { case idle, monitoring, lowBudget, shielded, pomodoro, disqualified }

    private var status: Status {
        if screenTime.disqualified { return .disqualified }
        if screenTime.pomodoroActive { return .pomodoro }
        if screenTime.shielded { return .shielded }
        if screenTime.monitoringStartedAt != nil {
            return screenTime.remainingMinutes < 15 ? .lowBudget : .monitoring
        }
        return .idle
    }

    private var gaugeProgress: Double {
        switch status {
        case .idle: return 0.0
        case .pomodoro:
            guard let end = screenTime.pomodoroEndsAt else { return 0.5 }
            let total = Double(AppConstants.pomodoroMinutes * 60)
            let remaining = max(0, end.timeIntervalSince(now))
            return 1.0 - (remaining / total)
        case .monitoring, .lowBudget:
            let used = Double(screenTime.minutesUsedToday)
            return min(1.0, used / Double(AppConstants.dailyLimitMinutes))
        case .shielded, .disqualified: return 1.0
        }
    }

    private var gaugeTint: Color {
        switch status {
        case .idle: return Theme.textSecondary
        case .monitoring, .pomodoro: return Theme.accent
        case .lowBudget: return Theme.warning
        case .shielded, .disqualified: return Theme.danger
        }
    }

    private var statusBadge: String {
        switch status {
        case .idle: return "Idle"
        case .monitoring: return "Safe"
        case .pomodoro: return "Deep Work"
        case .lowBudget: return "Low Budget"
        case .shielded: return "Shielded"
        case .disqualified: return "Disqualified"
        }
    }

    private var statusBadgeColor: Color {
        gaugeTint
    }

    private var centerValue: String {
        switch status {
        case .pomodoro:
            guard let end = screenTime.pomodoroEndsAt else { return "25:00" }
            let remaining = max(0, Int(end.timeIntervalSince(now)))
            return String(format: "%d:%02d", remaining / 60, remaining % 60)
        default:
            return "\(screenTime.remainingMinutes)"
        }
    }

    private var centerLabel: String {
        switch status {
        case .pomodoro: return "min left"
        case .shielded, .disqualified: return "shielded"
        default: return "min budget"
        }
    }

    private var canStart: Bool {
        screenTime.authState == .authorized && screenTime.hasAppsSelected
    }

    private var alreadySubmittedToday: Bool {
        lastSubmittedDay == ISO8601Day.todayString()
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 28) {
                    header
                    if screenTime.disqualified {
                        disqualifiedBanner
                    } else if screenTime.authState == .denied {
                        authDeniedBanner
                    }
                    gauge
                    statusLine
                    actions
                }
                .padding(28)
                .frame(maxWidth: .infinity, minHeight: 700)
            }
        }
        .sheet(isPresented: $showingPicker) {
            AppSelectionView(initial: screenTime.selection)
                .environmentObject(screenTime)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingProductivePass) {
            ProductivePassView(initial: screenTime.productivePass)
                .environmentObject(screenTime)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingUnlock) {
            EmergencyUnlockView()
                .environmentObject(screenTime)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(screenTime)
                .preferredColorScheme(.dark)
        }
        .onAppear {
            restoreLastSubmittedDay()
            screenTime.sendHeartbeat()
            autoSubmitIfDue()
        }
        .onReceive(timer) { now = $0 }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Last Scroll")
                    .font(.system(.title3, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(statusBadge)
                    .font(.caption2)
                    .textCase(.uppercase)
                    .tracking(2)
                    .foregroundStyle(statusBadgeColor)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(streak)")
                    .font(.system(.title2, weight: .light).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
                Text("day streak")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.leading, 14)
            }
            .accessibilityLabel("Settings")
        }
    }

    private var disqualifiedBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Disqualified for today")
                .font(.callout.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
            Text("Screen Time access was revoked while monitoring was active. Re-enable it to continue tomorrow.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.danger.opacity(0.8), lineWidth: 1)
        )
        .cornerRadius(8)
    }

    private var authDeniedBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Screen Time access denied")
                .font(.callout.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
            Text("Open Settings → Screen Time → Family Controls and allow Last Scroll.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Button("Open Settings") {
                screenTime.openSystemSettings()
            }
            .font(.callout.weight(.medium))
            .foregroundStyle(Theme.accent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.danger.opacity(0.7), lineWidth: 1)
        )
        .cornerRadius(8)
    }

    private var gauge: some View {
        CircularGaugeView(
            progress: gaugeProgress,
            centerValue: centerValue,
            centerLabel: centerLabel,
            tint: gaugeTint
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(centerValue) \(centerLabel), \(statusBadge)")
    }

    private var statusLine: some View {
        VStack(spacing: 6) {
            HStack(spacing: 16) {
                stat(label: "Used", value: "\(screenTime.minutesUsedToday)m")
                stat(label: "Cap", value: "\(AppConstants.dailyLimitMinutes)m")
                stat(label: "Score", value: "\(screenTime.todayScore)")
            }
            switch status {
            case .idle:
                Text(canStart ? "Ready to start the day" : "Pick distraction apps to begin")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            case .monitoring:
                Text("Tracking — productive apps don't count")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            case .lowBudget:
                Text("Under 15 minutes left — slow down")
                    .font(.caption)
                    .foregroundStyle(Theme.warning)
            case .pomodoro:
                Text("Deep Work focus session — apps shielded")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
            case .shielded:
                Text("Apps blocked until midnight")
                    .font(.caption)
                    .foregroundStyle(Theme.danger)
            case .disqualified:
                Text("Today's score is locked at zero")
                    .font(.caption)
                    .foregroundStyle(Theme.danger)
            }
            if let submitMessage {
                Text(submitMessage)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func stat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.callout.monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.caption2)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            primaryButton("Choose distraction apps") { showingPicker = true }
            primaryButton("Productive Pass (whitelist)") { showingProductivePass = true }
            primaryButton(status == .idle ? "Start day" : "Restart day") {
                UISelectionFeedbackGenerator().selectionChanged()
                try? screenTime.startMonitoring()
            }
            .opacity(canStart ? 1 : 0.4)
            .disabled(!canStart)

            if status == .pomodoro {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    screenTime.cancelPomodoro()
                } label: {
                    Text("End Deep Work early")
                        .font(.callout)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            } else {
                primaryButton("Deep Work · 25 min") {
                    UISelectionFeedbackGenerator().selectionChanged()
                    try? screenTime.startPomodoro()
                }
                .opacity(canStart ? 1 : 0.4)
                .disabled(!canStart)
            }

            if status == .shielded {
                Button { showingUnlock = true } label: {
                    Text("Emergency unlock")
                        .font(.callout)
                        .foregroundStyle(Theme.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }

            if SupabaseService.shared.isConfigured {
                Button {
                    Task { await submitStreak() }
                } label: {
                    HStack(spacing: 8) {
                        if submitting { ProgressView().scaleEffect(0.7) }
                        Text(alreadySubmittedToday ? "Submitted" : "Submit to leaderboard")
                            .font(.footnote)
                            .foregroundStyle(alreadySubmittedToday ? Theme.success : Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .disabled(submitting || alreadySubmittedToday)
            }
        }
    }

    private func primaryButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.callout.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.surface)
                .cornerRadius(8)
        }
    }

    private func restoreLastSubmittedDay() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroup)
        lastSubmittedDay = defaults?.string(forKey: SharedKeys.lastSubmittedDay)
    }

    private func autoSubmitIfDue() {
        let hour = Calendar.current.component(.hour, from: Date())
        guard SupabaseService.shared.isConfigured,
              hour >= AppConstants.autoSyncHour,
              !alreadySubmittedToday else { return }
        Task { await submitStreak() }
    }

    private func submitStreak() async {
        submitting = true
        defer { submitting = false }
        let day = ISO8601Day.todayString()
        do {
            try await SupabaseService.shared.upsertStreak(
                userId: screenTime.stableUserId,
                score: screenTime.todayScore,
                day: day,
                minutesUsed: screenTime.minutesUsedToday,
                shielded: screenTime.shielded
            )
            let defaults = UserDefaults(suiteName: AppConstants.appGroup)
            defaults?.set(day, forKey: SharedKeys.lastSubmittedDay)
            defaults?.set(screenTime.todayScore, forKey: SharedKeys.lastSubmittedScore)
            lastSubmittedDay = day
            submitMessage = "Submitted score: \(screenTime.todayScore)"
        } catch SupabaseError.notConfigured {
            submitMessage = "Leaderboard not configured"
        } catch {
            submitMessage = "Submit failed — try again"
        }
    }
}
