import SwiftUI
import UIKit

struct ControlCenterView: View {
    @EnvironmentObject var screenTime: ScreenTimeManager
    @State private var showingPicker = false
    @State private var showingUnlock = false
    @State private var nowTick = Date()
    @State private var submitting = false
    @State private var submitMessage: String?

    private var minutesUsed: Int {
        guard let start = screenTime.monitoringStartedAt else { return 0 }
        let elapsed = Int(nowTick.timeIntervalSince(start) / 60)
        return min(Theme.dailyLimitMinutes, max(0, elapsed))
    }
    private var minutesRemaining: Int {
        screenTime.shielded ? 0 : max(0, Theme.dailyLimitMinutes - minutesUsed)
    }
    private var progress: Double {
        screenTime.shielded ? 1.0 : Double(minutesUsed) / Double(Theme.dailyLimitMinutes)
    }
    private var canStart: Bool {
        !screenTime.selection.applicationTokens.isEmpty ||
        !screenTime.selection.categoryTokens.isEmpty
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 28) {
                header
                Spacer(minLength: 0)
                CircularGaugeView(
                    progress: progress,
                    centerValue: "\(minutesRemaining)",
                    centerLabel: "minutes left",
                    tint: screenTime.shielded ? Theme.danger : Theme.accent
                )
                statusLine
                Spacer(minLength: 0)
                actions
            }
            .padding(28)
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
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
            nowTick = Date()
            screenTime.refreshState()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dopamine Detox")
                    .font(.system(.title3, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(statusBadge)
                    .font(.caption2)
                    .textCase(.uppercase)
                    .tracking(2)
                    .foregroundStyle(screenTime.shielded ? Theme.danger : Theme.textSecondary)
            }
            Spacer()
        }
    }

    private var statusBadge: String {
        if screenTime.shielded { return "Shielded" }
        if screenTime.monitoringStartedAt != nil { return "Monitoring" }
        return "Idle"
    }

    private var statusLine: some View {
        VStack(spacing: 6) {
            Text("Daily limit \(Theme.dailyLimitMinutes) min")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            if !canStart {
                Text("No distraction apps selected")
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
            primaryButton(screenTime.monitoringStartedAt == nil ? "Start day" : "Restart day") {
                try? screenTime.startMonitoring()
            }
            .opacity(canStart ? 1 : 0.4)
            .disabled(!canStart)

            if screenTime.shielded {
                Button { showingUnlock = true } label: {
                    Text("Emergency unlock")
                        .font(.callout)
                        .foregroundStyle(Theme.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }

            Button {
                Task { await submitScore() }
            } label: {
                HStack(spacing: 8) {
                    if submitting { ProgressView().scaleEffect(0.7) }
                    Text("Submit today's score")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .disabled(submitting)
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

    private func submitScore() async {
        submitting = true
        defer { submitting = false }
        let score = minutesRemaining
        let userId = UIDevice.current.identifierForVendor?.uuidString ?? "anonymous"
        do {
            try await SupabaseService.shared.postDailyScore(userId: userId, score: score)
            submitMessage = "Score \(score) submitted"
        } catch {
            submitMessage = "Submit failed"
        }
    }
}
