import SwiftUI

@main
struct DopamineDetoxApp: App {
    @StateObject private var screenTime = ScreenTimeManager()
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootView()
                        .environmentObject(screenTime)
                } else {
                    OnboardingView(hasOnboarded: $hasOnboarded)
                        .environmentObject(screenTime)
                }
            }
            .preferredColorScheme(.dark)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    screenTime.refreshState()
                    screenTime.resolveYesterdayIfNeeded()
                    screenTime.syncAuthorizationStatus()
                }
            }
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            ControlCenterView()
                .tabItem { Label("Control", systemImage: "shield.lefthalf.filled") }
            LeaderboardView()
                .tabItem { Label("Leaderboard", systemImage: "trophy") }
        }
        .tint(Theme.accent)
    }
}
