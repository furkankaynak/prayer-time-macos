import SwiftUI
import Adhan

struct FloatingPanelView: View {

    let prayerName: String
    let prayerSymbol: String
    let prayerTime: Date
    let panelWidth: CGFloat
    let panelHeight: CGFloat
    let onDismiss: () -> Void

    private var cornerRadius: CGFloat { panelHeight / 2 }
    private let horizontalPadding: CGFloat = 24
    private let centerGapWidth: CGFloat = 120
    private var sideColumnWidth: CGFloat {
        max((panelWidth - (horizontalPadding * 2) - centerGapWidth) / 2, 0)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: prayerSymbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.orange)

                    Text(prayerName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(width: sideColumnWidth, alignment: .leading)

                Color.clear
                    .frame(width: centerGapWidth, height: 1)
                    .accessibilityHidden(true)

                Text(countdownText(at: context.date))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .frame(width: sideColumnWidth, alignment: .trailing)
            }
            .padding(.horizontal, horizontalPadding)
            .frame(width: panelWidth, height: panelHeight, alignment: .center)
            .background(
                Color(red: 0.027, green: 0.027, blue: 0.027),
                in: UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius, topTrailingRadius: 0, style: .continuous)
            )
            .overlay {
                UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius, topTrailingRadius: 0, style: .continuous)
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
