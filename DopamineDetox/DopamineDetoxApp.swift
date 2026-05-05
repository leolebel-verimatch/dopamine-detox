import SwiftUI

@main
struct DopamineDetoxApp: App {
    @StateObject private var screenTime = ScreenTimeManager()

    var body: some Scene {
        WindowGroup {
            ControlCenterView()
                .environmentObject(screenTime)
                .preferredColorScheme(.dark)
                .task { await screenTime.requestAuthorization() }
        }
    }
}
