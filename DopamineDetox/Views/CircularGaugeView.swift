import SwiftUI

struct CircularGaugeView: View {
    let progress: Double
    let centerValue: String
    let centerLabel: String
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surface, lineWidth: 14)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)

            VStack(spacing: 6) {
                Text(centerValue)
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
                Text(centerLabel)
                    .font(.caption)
                    .textCase(.uppercase)
                    .tracking(2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(width: 280, height: 280)
    }
}
