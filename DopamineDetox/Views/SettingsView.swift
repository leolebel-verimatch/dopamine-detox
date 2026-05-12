import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var screenTime: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedGrade: GradeLevel = .eleven

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        section(title: "Grade") {
                            VStack(spacing: 0) {
                                ForEach(GradeLevel.allCases) { grade in
                                    Button {
                                        selectedGrade = grade
                                        screenTime.grade = grade
                                        Haptics.selection()
                                    } label: {
                                        HStack {
                                            Text(grade.rawValue)
                                                .foregroundStyle(Theme.textPrimary)
                                            Spacer()
                                            if selectedGrade == grade {
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(Theme.accent)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                    Divider().background(Theme.surfaceElevated)
                                }
                            }
                            .background(Theme.surface)
                            .cornerRadius(10)
                        }

                        section(title: "How it works") {
                            Text("Last Scroll caps your daily use of distraction apps at 120 minutes. Productive Pass apps don't count. Deep Work shields everything for 25 minutes. Score posts to the school leaderboard.")
                                .font(.callout)
                                .foregroundStyle(Theme.textSecondary)
                                .padding(16)
                                .background(Theme.surface)
                                .cornerRadius(10)
                        }

                        section(title: "Links") {
                            VStack(spacing: 0) {
                                link("Privacy Policy", url: "https://leolebel-verimatch.github.io/dopamine-detox/privacy.html")
                                Divider().background(Theme.surfaceElevated)
                                link("Support", url: "https://leolebel-verimatch.github.io/dopamine-detox/support.html")
                                Divider().background(Theme.surfaceElevated)
                                link("Terms", url: "https://leolebel-verimatch.github.io/dopamine-detox/terms.html")
                            }
                            .background(Theme.surface)
                            .cornerRadius(10)
                        }

                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            if let grade = screenTime.grade {
                selectedGrade = grade
            }
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2)
                .tracking(2)
                .foregroundStyle(Theme.textSecondary)
            content()
        }
    }

    private func link(_ label: String, url: String) -> some View {
        Button {
            if let u = URL(string: url) { UIApplication.shared.open(u) }
        } label: {
            HStack {
                Text(label).foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right.square").foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
