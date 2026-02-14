import SwiftUI

@MainActor
final class AppState: ObservableObject {
    let settingsViewModel: SettingsViewModel
    let locationService: LocationService
    let notificationService: NotificationService
    let prayerViewModel: PrayerViewModel
    let locationViewModel: LocationViewModel

    init() {
        let settings = SettingsViewModel()
        let location = LocationService()
        let notification = NotificationService()

        self.settingsViewModel = settings
        self.locationService = location
        self.notificationService = notification
        self.prayerViewModel = PrayerViewModel(
            settingsViewModel: settings,
            notificationService: notification
        )
        self.locationViewModel = LocationViewModel(
            locationService: location,
            settingsViewModel: settings
        )
    }
}

@main
struct PrayerTimeApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MainView()
                .environmentObject(appState.prayerViewModel)
                .environmentObject(appState.settingsViewModel)
                .environmentObject(appState.locationViewModel)
                .environmentObject(appState.locationService)
                .environmentObject(appState.notificationService)
        } label: {
            Label(
                appState.prayerViewModel.menuBarText,
                systemImage: appState.prayerViewModel.menuBarSymbol
            )
        }
        .menuBarExtraStyle(.window)
    }
}
