import SwiftUI
import Adhan

struct FloatingPanelView: View {

    let prayerName: String
    let prayerSymbol: String
    let prayerTime: Date
    let onDismiss: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 12) {
                Image(systemName: prayerSymbol)
                    .font(.title2)
                    .foregroundStyle(.orange)

                Text(prayerName)
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Text(countdownText(at: context.date))
                    .font(.system(.title3, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(width: 320, height: 52)
            .background(
                Color(red: 0.027, green: 0.027, blue: 0.027),
                in: UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 26, bottomTrailingRadius: 26, topTrailingRadius: 0, style: .continuous)
            )
            .overlay {
                UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 26, bottomTrailingRadius: 26, topTrailingRadius: 0, style: .continuous)
                    .stroke(
                        .white.opacity(0.04),
                        lineWidth: 0.5
                    )
            }
        }
        .onTapGesture {
            onDismiss()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prayerName) prayer reminder")
        .accessibilityHint("Tap to dismiss")
        .accessibilityAddTraits(.isButton)
    }

    private func countdownText(at now: Date) -> String {
        let interval = Int(prayerTime.timeIntervalSince(now))
        guard interval > 0 else { return "Now" }

        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
