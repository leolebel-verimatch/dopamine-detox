import UIKit

enum Haptics {
    @MainActor
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    @MainActor
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// "Heartbeat" rhythm — two close-together impacts, pause, two more. Fires once
    /// per day when minutes used crosses 90% of the budget.
    @MainActor
    static func heartbeat() {
        let medium = UIImpactFeedbackGenerator(style: .medium)
        let soft = UIImpactFeedbackGenerator(style: .soft)
        medium.prepare()
        soft.prepare()
        medium.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            soft.impactOccurred(intensity: 0.7)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            medium.impactOccurred(intensity: 1.0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.03) {
            soft.impactOccurred(intensity: 0.7)
        }
    }
}
