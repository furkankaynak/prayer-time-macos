import AppKit
import SwiftUI

@MainActor
final class FloatingPanelManager {

    private var panel: FloatingPanel?
    private var autoDismissTask: Task<Void, Never>?

    func show(prayerName: String, prayerSymbol: String, prayerTime: Date, onDismiss: @escaping () -> Void) {
        dismiss()

        let view = FloatingPanelView(
            prayerName: prayerName,
            prayerSymbol: prayerSymbol,
            prayerTime: prayerTime,
            onDismiss: { [weak self] in
                self?.dismiss()
                onDismiss()
            }
        )

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 300, height: 56)

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
}
