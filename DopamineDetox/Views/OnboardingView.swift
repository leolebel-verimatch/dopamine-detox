import SwiftUI

struct OnboardingView: View {
    @Binding var hasOnboarded: Bool
    @EnvironmentObject var screenTime: ScreenTimeManager
    @State private var page: Int = 0
    @State private var selectedGrade: GradeLevel = .eleven

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    pageOne.tag(0)
                    pageTwo.tag(1)
                    pageThree.tag(2)
                    pageFour.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots
                    .padding(.bottom, 8)

                actionButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .onAppear {
            if let saved = screenTime.grade {
                selectedGrade = saved
            }
        }
    }

    private var pageOne: some View {
        page(
            title: "Cap the feeds",
            body: "Pick the apps that drain your day. After 120 minutes of combined use they go dark for the rest of the day."
        )
    }

    private var pageTwo: some View {
        page(
            title: "Build a streak",
            body: "Every clean day earns up to 120 points. Shield early for a +25 Hardcore bonus. Your score posts to the school leaderboard."
        )
    }

    private var pageThree: some View {
        page(
            title: "Productive Pass + Deep Work",
            body: "Whitelist schoolwork apps so they never count. Trigger a 25-minute focus shield whenever you need it."
        )
    }

    private var pageFour: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Pick your grade")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Text("We use this to tune the motivational message on the shield screen.")
                .font(.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            VStack(spacing: 0) {
                ForEach(GradeLevel.allCases) { grade in
                    Button {
                        selectedGrade = grade
                        Haptics.selection()
                    } label: {
                        HStack {
                            Text(grade.rawValue)
                                .font(.callout)
                                .foregroundStyle(selectedGrade == grade ? Theme.accent : Theme.textPrimary)
                            Spacer()
                            if selectedGrade == grade {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(selectedGrade == grade ? Theme.surface : Color.clear)
                    }
                    Divider().background(Theme.surfaceElevated)
                }
            }
            .background(Theme.surface.opacity(0.4))
            .cornerRadius(10)
            .padding(.horizontal, 32)
            Spacer()
        }
    }

    private func page(title: String, body: String) -> some View {
        VStack(spacing: 18) {
            Spacer()
            Text(title)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Text(body)
                .font(.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(i == page ? Theme.accent : Theme.surface)
                    .frame(width: 7, height: 7)
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if page < 3 {
            Button {
                Haptics.selection()
                withAnimation { page += 1 }
            } label: {
                Text("Continue")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.surface)
                    .cornerRadius(8)
            }
        } else {
            Button {
                screenTime.grade = selectedGrade
                Task {
                    await screenTime.requestAuthorization()
                    hasOnboarded = true
                }
            } label: {
                Text("Grant Screen Time access")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .cornerRadius(8)
            }
        }
    }
}
