import SwiftUI
import FamilyControls

struct ProductivePassView: View {
    @EnvironmentObject var screenTime: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss
    @State private var draft: FamilyActivitySelection

    init(initial: FamilyActivitySelection) {
        _draft = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                hint
                FamilyActivityPicker(selection: $draft)
            }
            .background(Theme.background)
            .navigationTitle("Productive Pass")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        screenTime.saveProductivePass(draft)
                        dismiss()
                    }
                }
            }
        }
    }

    private var hint: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Apps on the Productive Pass never count against the daily budget.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Text("Suggested: Canvas, Google Classroom, Notion, Calculator, Calendar, Mail.")
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface)
    }
}
