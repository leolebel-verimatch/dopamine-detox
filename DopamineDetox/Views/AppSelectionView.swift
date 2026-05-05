import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @EnvironmentObject var screenTime: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss
    @State private var draft: FamilyActivitySelection

    init(initial: FamilyActivitySelection) {
        _draft = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            FamilyActivityPicker(selection: $draft)
                .navigationTitle("Distractions")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            screenTime.saveSelection(draft)
                            dismiss()
                        }
                    }
                }
        }
    }
}
