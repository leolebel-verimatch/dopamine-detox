import SwiftUI

struct OnboardingView: View {
    @Binding var hasOnboarded: Bool
    @EnvironmentObject var screenTime: ScreenTimeManager
    @State private var page: Int = 0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    pageOne.tag(0)
                    pageTwo.tag(1)
                    pageThree.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots
                    .padding(.bottom, 8)

                actionButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
    }

    private var pageOne: some View {
        page(
            title: "Cap the feeds",
            body: "Pick the apps that drain your day. After 120 minutes of combined use, they go dark for the rest of the day."
        )
    }

    private var pageTwo: some View {
        page(
            title: "Build a streak",
            body: "Every day you stay under the limit extends your streak. Get shielded and it resets to zero."
        )
    }

    private var pageThree: some View {
        page(
            title: "No easy outs",
            body: "There's an emergency unlock, but it costs you a long sentence to type. Friction is the point."
        )
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
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i == page ? Theme.accent : Theme.surface)
                    .frame(width: 7, height: 7)
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if page < 2 {
            Button {
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
                Task {
                    await screenTime.requestAuthorization()
                    hasOnboarded = true
                }
            } label: {
                Text("Grant Screen Time access")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .cornerRadius(8)
            }
        }
    }
}
