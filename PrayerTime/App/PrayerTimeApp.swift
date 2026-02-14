import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    let settingsViewModel: SettingsViewModel
    let locationService: LocationService
    let notificationService: NotificationService
    let prayerViewModel: PrayerViewModel
    let locationViewModel: LocationViewModel
    let floatingPanelManager = FloatingPanelManager()

    private var cancellables = Set<AnyCancellable>()

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

        observeFloatingPanel()
    }

    private func observeFloatingPanel() {
        prayerViewModel.$shouldShowFloatingPanel
            .removeDuplicates()
            .sink { [weak self] shouldShow in
                guard let self else { return }
                if shouldShow,
                   let prayer = self.prayerViewModel.nextPrayer,
                   let time = self.prayerViewModel.nextPrayerTime {
                    self.floatingPanelManager.show(
                        prayerName: prayer.displayName,
                        prayerSymbol: prayer.sfSymbol,
                        prayerTime: time,
                        onDismiss: { [weak self] in
                            self?.prayerViewModel.dismissFloatingPanel()
                        }
                    )
                } else {
                    self.floatingPanelManager.dismiss()
                }
            }
            .store(in: &cancellables)
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
