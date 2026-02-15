import AppKit
import SwiftUI

@MainActor
final class FloatingPanelManager {

    private let expandedPanelWidth: CGFloat = 360
    private let collapsedPanelWidth: CGFloat = 300
    private let openAnimationDuration: TimeInterval = 0.3
    private let minimumPanelHeight: CGFloat = 28
    private let fallbackPanelHeight: CGFloat = 52

    private var panel: FloatingPanel?
    private var autoDismissTask: Task<Void, Never>?

    func show(prayerName: String, prayerSymbol: String, prayerTime: Date, onDismiss: @escaping () -> Void) {
        dismiss()

        let panelHeight = currentMenuBarHeight()

        let view = FloatingPanelView(
            prayerName: prayerName,
            prayerSymbol: prayerSymbol,
            prayerTime: prayerTime,
            expandedWidth: expandedPanelWidth,
            collapsedWidth: collapsedPanelWidth,
            panelHeight: panelHeight,
            openAnimationDuration: openAnimationDuration,
            onDismiss: { [weak self] in
                self?.dismiss()
                onDismiss()
            }
        )

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: expandedPanelWidth, height: panelHeight)

        let floatingPanel = FloatingPanel(contentRect: hostingView.frame)
        floatingPanel.contentView = hostingView
        floatingPanel.positionAtTopCenter()
        floatingPanel.orderFront(nil)

        self.panel = floatingPanel

        // Auto-dismiss at prayer time
        let interval = prayerTime.timeIntervalSinceNow
        if interval > 0 {
            autoDismissTask = Task {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { return }
                self.dismiss()
                onDismiss()
            }
        }
    }

    func dismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        panel?.close()
        panel = nil
    }

    private func currentMenuBarHeight() -> CGFloat {
        guard let screen = NSScreen.main else { return fallbackPanelHeight }
        let menuBarHeight = screen.frame.height - screen.visibleFrame.height
        return max(menuBarHeight, minimumPanelHeight)
    }
}
