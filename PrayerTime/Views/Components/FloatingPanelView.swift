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
    let fullscreenHoverModeProvider: () -> Bool
    let onDismiss: () -> Void

    private var cornerRadius: CGFloat { panelHeight / 2 }
    private let horizontalPadding: CGFloat = 24
    private let centerGapWidth: CGFloat = 120
    private static let defaultCompactVisibleHeight: CGFloat = 4
    private let compactVisibleHeight: CGFloat = Self.defaultCompactVisibleHeight
    private let hoverCollapseDelay: TimeInterval = 0.6
    private var sideColumnWidth: CGFloat {
        max((expandedWidth - (horizontalPadding * 2) - centerGapWidth) / 2, 0)
    }

    @State private var animatedIslandWidth: CGFloat
    @State private var animatedIslandHeight: CGFloat
    @State private var isFullscreenHoverMode: Bool
    @State private var isContentVisible = false
    @State private var contentRevealTask: Task<Void, Never>?
    @State private var hoverCollapseTask: Task<Void, Never>?

    private let fullscreenModePollTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    init(
        prayerName: String,
        prayerSymbol: String,
        prayerTime: Date,
        expandedWidth: CGFloat,
        collapsedWidth: CGFloat,
        panelHeight: CGFloat,
        openAnimationDuration: TimeInterval,
        initialFullscreenHoverMode: Bool,
        fullscreenHoverModeProvider: @escaping () -> Bool,
        onDismiss: @escaping () -> Void
    ) {
        self.prayerName = prayerName
        self.prayerSymbol = prayerSymbol
        self.prayerTime = prayerTime
        let clampedCollapsedWidth = min(collapsedWidth, expandedWidth)
        self.expandedWidth = expandedWidth
        self.collapsedWidth = clampedCollapsedWidth
        self.panelHeight = panelHeight
        self.openAnimationDuration = openAnimationDuration
        self.fullscreenHoverModeProvider = fullscreenHoverModeProvider
        self.onDismiss = onDismiss
        _animatedIslandWidth = State(initialValue: clampedCollapsedWidth)
        _animatedIslandHeight = State(
            initialValue: initialFullscreenHoverMode ? Self.defaultCompactVisibleHeight : panelHeight
        )
        _isFullscreenHoverMode = State(initialValue: initialFullscreenHoverMode)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ZStack(alignment: .top) {
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
                .frame(width: animatedIslandWidth, height: animatedIslandHeight, alignment: .top)

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
                .frame(height: panelHeight)
                .opacity(isContentVisible ? 1 : 0)
            }
            .frame(width: expandedWidth, height: panelHeight, alignment: .top)
            .contentShape(Rectangle())
            .onHover(perform: handleHoverChange)
        }
        .onAppear {
            if isFullscreenHoverMode {
                startFullscreenHoverMode()
            } else {
                startOpeningAnimation()
            }
        }
        .onReceive(fullscreenModePollTimer) { _ in
            let latestFullscreenMode = fullscreenHoverModeProvider()
            guard latestFullscreenMode != isFullscreenHoverMode else { return }
            applyFullscreenMode(latestFullscreenMode)
        }
        .onDisappear {
            contentRevealTask?.cancel()
            contentRevealTask = nil
            hoverCollapseTask?.cancel()
            hoverCollapseTask = nil
        }
        .onTapGesture {
            if isFullscreenHoverMode && !isContentVisible {
                expandForHover()
            } else {
                onDismiss()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prayerName) prayer reminder")
        .accessibilityHint("Tap to dismiss")
        .accessibilityAddTraits(.isButton)
    }

    private func startOpeningAnimation() {
        contentRevealTask?.cancel()
        hoverCollapseTask?.cancel()
        isContentVisible = false
        animatedIslandWidth = collapsedWidth
        animatedIslandHeight = panelHeight

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

    private func startFullscreenHoverMode() {
        contentRevealTask?.cancel()
        hoverCollapseTask?.cancel()
        isContentVisible = false
        animatedIslandWidth = collapsedWidth
        animatedIslandHeight = compactVisibleHeight
    }

    private func handleHoverChange(_ isHovering: Bool) {
        guard isFullscreenHoverMode else { return }

        hoverCollapseTask?.cancel()
        hoverCollapseTask = nil

        if isHovering {
            expandForHover()
        } else {
            scheduleHoverCollapse()
        }
    }

    private func expandForHover() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.62, blendDuration: 0.12)) {
            animatedIslandWidth = expandedWidth
            animatedIslandHeight = panelHeight
        }

        withAnimation(.easeOut(duration: 0.12)) {
            isContentVisible = true
        }
    }

    private func scheduleHoverCollapse() {
        let delayNanos = UInt64(hoverCollapseDelay * 1_000_000_000)
        hoverCollapseTask = Task {
            try? await Task.sleep(nanoseconds: delayNanos)
            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.08)) {
                isContentVisible = false
            }

            withAnimation(.spring(response: 0.24, dampingFraction: 0.75, blendDuration: 0.1)) {
                animatedIslandWidth = collapsedWidth
                animatedIslandHeight = compactVisibleHeight
            }
        }
    }

    private func applyFullscreenMode(_ isFullscreen: Bool) {
        contentRevealTask?.cancel()
        hoverCollapseTask?.cancel()
        isFullscreenHoverMode = isFullscreen

        if isFullscreen {
            // Full → Compact: fade out content, then shrink to handle
            withAnimation(.easeOut(duration: 0.1)) {
                isContentVisible = false
            }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.72, blendDuration: 0.1)) {
                animatedIslandWidth = collapsedWidth
                animatedIslandHeight = compactVisibleHeight
            }
        } else {
            // Compact → Full: expand from current size, then fade in content
            withAnimation(.spring(response: 0.32, dampingFraction: 0.62, blendDuration: 0.12)) {
                animatedIslandWidth = expandedWidth
                animatedIslandHeight = panelHeight
            }

            contentRevealTask = Task {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.12)) {
                    isContentVisible = true
                }
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
