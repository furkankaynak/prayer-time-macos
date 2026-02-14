import SwiftUI
import Adhan

struct PrayerListView: View {

    let entries: [PrayerTimeEntry]
    let currentPrayer: Prayer?
    let nextPrayer: Prayer?
    let countdownText: String

    var body: some View {
        VStack(spacing: 0) {
            ForEach(entries) { entry in
                PrayerRow(
                    entry: entry,
                    isCurrent: entry.prayer == currentPrayer,
                    isNext: entry.prayer == nextPrayer,
                    countdownText: entry.prayer == nextPrayer ? countdownText : nil
                )
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Prayer Row

struct PrayerRow: View {

    let entry: PrayerTimeEntry
    let isCurrent: Bool
    let isNext: Bool
    let countdownText: String?

    private var isPast: Bool {
        !isCurrent && !isNext && entry.time < Date()
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.sfSymbol)
                .font(.system(size: 14))
                .frame(width: 20)
                .foregroundStyle(iconColor)

            Text(entry.displayName)
                .font(isNext ? .body.weight(.semibold) : .body)
                .foregroundStyle(textColor)

            Spacer()

            if let countdown = countdownText, !countdown.isEmpty {
                Text(countdown)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(0.12), in: Capsule())
            }

            Text(entry.formattedTime)
                .font(.body.monospacedDigit())
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var iconColor: Color {
        if isNext { return .orange }
        if isCurrent { return .blue }
        if isPast { return .secondary.opacity(0.5) }
        return .primary
    }

    private var textColor: Color {
        if isPast { return .secondary }
        return .primary
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isNext {
            Color.orange.opacity(0.08)
        } else {
            Color.clear
        }
    }
}
