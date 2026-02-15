import SwiftUI
import Adhan

struct FloatingPanelView: View {

    let prayerName: String
    let prayerSymbol: String
    let prayerTime: Date
    let expandedWidth: CGFloat
    let collapsedWidth: CGFloat
    let panelHeight: CGFloat
    let openAnimationDuration: TimeInterval
    let onDismiss: () -> Void

    private var cornerRadius: CGFloat { panelHeight / 2 }
    private let horizontalPadding: CGFloat = 24
    private let centerGapWidth: CGFloat = 120
    private var sideColumnWidth: CGFloat {
        max((expandedWidth - (horizontalPadding * 2) - centerGapWidth) / 2, 0)
    }

    @State private var animatedIslandWidth: CGFloat
    @State private var isContentVisible = false
    @State private var contentRevealTask: Task<Void, Never>?

    init(
        prayerName: String,
        prayerSymbol: String,
        prayerTime: Date,
        expandedWidth: CGFloat,
        collapsedWidth: CGFloat,
        panelHeight: CGFloat,
        openAnimationDuration: TimeInterval,
        onDismiss: @escaping () -> Void
    ) {
        self.prayerName = prayerName
        self.prayerSymbol = prayerSymbol
        self.prayerTime = prayerTime
        self.expandedWidth = expandedWidth
        self.collapsedWidth = min(collapsedWidth, expandedWidth)
        self.panelHeight = panelHeight
        self.openAnimationDuration = openAnimationDuration
        self.onDismiss = onDismiss
        _animatedIslandWidth = State(initialValue: min(collapsedWidth, expandedWidth))
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ZStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: 0,
                    style: .continuous
                )
                .fill(Color(red: 0.027, green: 0.027, blue: 0.027))
                .overlay {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: cornerRadius,
                        bottomTrailingRadius: cornerRadius,
                        topTrailingRadius: 0,
                        style: .continuous
                    )
                    .stroke(
                        .white.opacity(0.04),
                        lineWidth: 0.5
                    )
                }
                .frame(width: animatedIslandWidth, height: panelHeight)

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
                .opacity(isContentVisible ? 1 : 0)
            }
            .frame(width: expandedWidth, height: panelHeight, alignment: .center)
        }
        .onAppear(perform: startOpeningAnimation)
        .onDisappear {
            contentRevealTask?.cancel()
            contentRevealTask = nil
        }
        .onTapGesture {
            onDismiss()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prayerName) prayer reminder")
        .accessibilityHint("Tap to dismiss")
        .accessibilityAddTraits(.isButton)
    }

    private func startOpeningAnimation() {
        contentRevealTask?.cancel()
        isContentVisible = false
        animatedIslandWidth = collapsedWidth

        withAnimation(.spring(response: openAnimationDuration, dampingFraction: 0.58, blendDuration: 0.15)) {
            animatedIslandWidth = expandedWidth
        }

        let durationNanos = UInt64(openAnimationDuration * 1_000_000_000)
        contentRevealTask = Task {
            try? await Task.sleep(nanoseconds: durationNanos)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.08)) {
                isContentVisible = true
            }
        }
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
