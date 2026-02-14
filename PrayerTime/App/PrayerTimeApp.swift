import SwiftUI

@main
struct PrayerTimeApp: App {
    var body: some Scene {
        MenuBarExtra("PrayerTime", systemImage: "sun.max.fill") {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
