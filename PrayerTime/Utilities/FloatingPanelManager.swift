import AppKit
import os.log
import SwiftUI

// MARK: - Private CoreGraphics Server API for space type detection

private typealias CGSConnectionID = UInt32

@_silgen_name("CGSMainConnectionID")
private func CGSMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSCopyManagedDisplaySpaces")
private func CGSCopyManagedDisplaySpaces(_ conn: CGSConnectionID) -> CFArray

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PrayerTime", category: "FullscreenDetect")

/// Space type values from CoreGraphics Server.
private enum CGSSpaceType {
    static let fullscreen = 4
}

@MainActor
final class FloatingPanelManager {

    private let expandedPanelWidth: CGFloat = 360
    private let collapsedPanelWidth: CGFloat = 300
    private let openAnimationDuration: TimeInterval = 0.3
    private let minimumPanelHeight: CGFloat = 28
    private let fallbackPanelHeight: CGFloat = 52
    private let fullscreenLatchDuration: TimeInterval = 1.0

    private var panel: FloatingPanel?
    private var autoDismissTask: Task<Void, Never>?
    private var spaceChangeTask: Task<Void, Never>?
    private var activeSpaceObserver: NSObjectProtocol?
    private var lastFullscreenPositiveSignalAt: Date?

    /// Persisted fullscreen state, updated on each space change after a settling delay.
    private var persistedFullscreenSpace = false

    init() {
        activeSpaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleSpaceChange()
            }
        }

        // Evaluate initial state (app might launch on a fullscreen space)
        refreshFullscreenSpaceState()
    }

    deinit {
        if let activeSpaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activeSpaceObserver)
        }
        spaceChangeTask?.cancel()
    }

    func show(prayerName: String, prayerSymbol: String, prayerTime: Date, onDismiss: @escaping () -> Void) {
        dismiss()

        let panelHeight = currentMenuBarHeight()
        let useFullscreenHoverMode = isFullscreenDetected()

        let view = FloatingPanelView(
            prayerName: prayerName,
            prayerSymbol: prayerSymbol,
            prayerTime: prayerTime,
            expandedWidth: expandedPanelWidth,
            collapsedWidth: collapsedPanelWidth,
            panelHeight: panelHeight,
            openAnimationDuration: openAnimationDuration,
            initialFullscreenHoverMode: useFullscreenHoverMode,
            fullscreenHoverModeProvider: { [weak self] in
                self?.isFullscreenDetected() ?? false
            },
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

    // MARK: - Space Change Handling

    private func handleSpaceChange() {
        spaceChangeTask?.cancel()
        spaceChangeTask = Task {
            // Delay to let the system settle after the space transition animation
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            refreshFullscreenSpaceState()
        }
    }

    private func refreshFullscreenSpaceState() {
        let newState = isCurrentSpaceFullscreen()
        if newState != persistedFullscreenSpace {
            logger.notice("Fullscreen space state changed: \(newState)")
            persistedFullscreenSpace = newState
        }
    }

    // MARK: - Fullscreen Detection

    private func currentMenuBarHeight() -> CGFloat {
        guard let screen = NSScreen.main else { return fallbackPanelHeight }
        let menuBarHeight = screen.frame.height - screen.visibleFrame.height
        return max(menuBarHeight, minimumPanelHeight)
    }

    private func isFullscreenDetected() -> Bool {
        let now = Date()

        if persistedFullscreenSpace {
            lastFullscreenPositiveSignalAt = now
            return true
        }

        // Real-time check as fallback (e.g. space change not yet processed)
        let realtime = isCurrentSpaceFullscreen()
        if realtime {
            lastFullscreenPositiveSignalAt = now
            return true
        }

        // Latch: hold positive state briefly to avoid flicker during transitions
        guard let lastFullscreenPositiveSignalAt else {
            return false
        }

        return now.timeIntervalSince(lastFullscreenPositiveSignalAt) <= fullscreenLatchDuration
    }

    /// Queries the private CGS API to determine if the current space is a fullscreen space.
    /// This is the only reliable method for sandboxed, non-activating, canJoinAllSpaces apps —
    /// public APIs (currentSystemPresentationOptions, NSScreen.visibleFrame) return stale
    /// values that don't reflect the active space for this type of app.
    private func isCurrentSpaceFullscreen() -> Bool {
        let conn = CGSMainConnectionID()
        guard let displays = CGSCopyManagedDisplaySpaces(conn) as? [[String: Any]] else {
            return false
        }

        for display in displays {
            guard let currentSpace = display["Current Space"] as? [String: Any],
                  let spaceType = currentSpace["type"] as? Int else {
                continue
            }

            if spaceType == CGSSpaceType.fullscreen {
                return true
            }
        }

        return false
    }
}
