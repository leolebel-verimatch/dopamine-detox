import SwiftUI

struct ControlCenterView: View {
    @EnvironmentObject var screenTime: ScreenTimeManager
    @State private var showingPicker = false
    @State private var showingUnlock = false
    @State private var submitting = false
    @State private var submitMessage: String?
    @State private var lastSubmittedDay: String?

    private var streak: Int { screenTime.history.currentStreak }

    private enum Status { case idle, monitoring, shielded }

    private var status: Status {
        if screenTime.shielded { return .shielded }
        if screenTime.monitoringStartedAt != nil { return .monitoring }
        return .idle
    }

    private var gaugeProgress: Double {
        switch status {
        case .idle: return 0
        case .monitoring: return 0.5
        case .shielded: return 1.0
        }
    }

    private var gaugeTint: Color {
        switch status {
        case .idle: return Theme.textSecondary
        case .monitoring: return Theme.accent
        case .shielded: return Theme.danger
        }
    }

    private var statusBadge: String {
        switch status {
        case .idle: return "Idle"
        case .monitoring: return "Monitoring"
        case .shielded: return "Shielded"
        }
    }

    private var statusBadgeColor: Color {
        switch status {
        case .idle: return Theme.textSecondary
        case .monitoring: return Theme.accent
        case .shielded: return Theme.danger
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
                    if screenTime.authState == .denied {
                        authDeniedBanner
                    }
                    gauge
                    statusLine
                    actions
                }
                .padding(28)
                .frame(minHeight: UIScreen.main.bounds.height - 80)
            }
        }
        .sheet(isPresented: $showingPicker) {
            AppSelectionView(initial: screenTime.selection)
                .environmentObject(screenTime)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingUnlock) {
            EmergencyUnlockView()
                .environmentObject(screenTime)
                .preferredColorScheme(.dark)
        }
        .onAppear { restoreLastSubmittedDay() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dopamine Cap")
                    .font(.system(.title3, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(statusBadge)
                    .font(.caption2)
                    .textCase(.uppercase)
                    .tracking(2)
                    .foregroundStyle(statusBadgeColor)
            }
            Spacer()
        }
    }

    private var authDeniedBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Screen Time access denied")
                .font(.callout.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
            Text("Open Settings → Screen Time → Family Controls and allow Dopamine Detox.")
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
            centerValue: "\(streak)",
            centerLabel: streak == 1 ? "day streak" : "day streak",
            tint: gaugeTint
        )
    }

    private var statusLine: some View {
        VStack(spacing: 6) {
            Text("Daily limit \(AppConstants.dailyLimitMinutes) minutes")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            switch status {
            case .idle:
                Text(canStart ? "Ready to start your day" : "Pick distraction apps to begin")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            case .monitoring:
                Text("Tracking against your selected apps")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            case .shielded:
                Text("Apps blocked until midnight")
                    .font(.caption)
                    .foregroundStyle(Theme.danger.opacity(0.85))
            }
            if let submitMessage {
                Text(submitMessage)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            primaryButton("Choose distraction apps") { showingPicker = true }
            primaryButton(status == .idle ? "Start day" : "Restart day") {
                try? screenTime.startMonitoring()
            }
            .opacity(canStart ? 1 : 0.4)
            .disabled(!canStart)

            if status == .shielded {
                Button { showingUnlock = true } label: {
                    Text("Emergency unlock")
                        .font(.callout)
                        .foregroundStyle(Theme.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }

            Button {
                Task { await submitStreak() }
            } label: {
                HStack(spacing: 8) {
                    if submitting { ProgressView().scaleEffect(0.7) }
                    Text(alreadySubmittedToday ? "Streak submitted" : "Submit streak to leaderboard")
                        .font(.footnote)
                        .foregroundStyle(alreadySubmittedToday ? Theme.success : Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .disabled(submitting || alreadySubmittedToday)
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

    private func submitStreak() async {
        submitting = true
        defer { submitting = false }
        let day = ISO8601Day.todayString()
        do {
            try await SupabaseService.shared.upsertStreak(
                userId: screenTime.stableUserId,
                score: streak,
                day: day
            )
            let defaults = UserDefaults(suiteName: AppConstants.appGroup)
            defaults?.set(day, forKey: SharedKeys.lastSubmittedDay)
            defaults?.set(streak, forKey: SharedKeys.lastSubmittedScore)
            lastSubmittedDay = day
            submitMessage = "Submitted streak: \(streak)"
        } catch SupabaseError.notConfigured {
            submitMessage = "Leaderboard not configured"
        } catch {
            submitMessage = "Submit failed — try again"
        }
    }
}
