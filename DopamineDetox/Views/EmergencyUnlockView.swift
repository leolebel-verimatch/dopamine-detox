import SwiftUI

struct EmergencyUnlockView: View {
    @EnvironmentObject var screenTime: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss
    @State private var typed: String = ""

    private var matches: Bool { UnlockChallenge.matches(typed) }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                Text("Emergency unlock")
                    .font(.system(.title3, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)

                Text("Type the sentence below exactly to lift the shield. Friction is the point.")
                    .font(.callout)
                    .foregroundStyle(Theme.textSecondary)

                Text(UnlockChallenge.phrase)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Theme.accent)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface)
                    .cornerRadius(8)

                TextEditor(text: $typed)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Theme.surface)
                    .cornerRadius(8)
                    .frame(minHeight: 160)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Button {
                    screenTime.liftShield()
                    dismiss()
                } label: {
                    Text("Lift shield")
                        .font(.callout.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(matches ? Theme.danger : Theme.surface)
                        .foregroundStyle(matches ? .white : Theme.textSecondary)
                        .cornerRadius(8)
                }
                .disabled(!matches)

                Button("Cancel") { dismiss() }
                    .font(.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(28)
        }
    }
}
