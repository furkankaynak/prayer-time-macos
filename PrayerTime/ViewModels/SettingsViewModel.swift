import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {

    @Published var savedLocation: SavedLocation? {
        didSet { persistLocation() }
    }

    @Published var selectedMethod: CalculationMethodOption {
        didSet { persistMethod() }
    }

    @Published var selectedMadhab: MadhabOption {
        didSet { persistMadhab() }
    }

    @Published var notificationMinutesBefore: Int {
        didSet { persistNotificationMinutes() }
    }

    @Published var showFloatingPanel: Bool {
        didSet { persistFloatingPanel() }
    }

    @Published var alwaysShowDynamicIsland: Bool {
        didSet { persistAlwaysShowDynamicIsland() }
    }

    private let calculationService = PrayerCalculationService()
    private let defaults = UserDefaults.standard

    init() {
        // Load saved location
        if let data = defaults.data(forKey: AppSettingsKeys.savedLocation),
           let location = try? JSONDecoder().decode(SavedLocation.self, from: data) {
            self.savedLocation = location
        } else {
            self.savedLocation = nil
        }

        // Load calculation method
        if let raw = defaults.string(forKey: AppSettingsKeys.calculationMethod),
           let method = CalculationMethodOption(rawValue: raw) {
            self.selectedMethod = method
        } else {
            self.selectedMethod = AppDefaults.calculationMethod
        }

        // Load madhab
        if let raw = defaults.string(forKey: AppSettingsKeys.madhab),
           let madhab = MadhabOption(rawValue: raw) {
            self.selectedMadhab = madhab
        } else {
            self.selectedMadhab = AppDefaults.madhab
        }

        // Load notification minutes
        let minutes = defaults.integer(forKey: AppSettingsKeys.notificationMinutesBefore)
        self.notificationMinutesBefore = minutes > 0 ? minutes : AppDefaults.notificationMinutesBefore

        // Load floating panel
        if defaults.object(forKey: AppSettingsKeys.showFloatingPanel) != nil {
            self.showFloatingPanel = defaults.bool(forKey: AppSettingsKeys.showFloatingPanel)
        } else {
            self.showFloatingPanel = AppDefaults.showFloatingPanel
        }

        // Load always show dynamic island
        if defaults.object(forKey: AppSettingsKeys.alwaysShowDynamicIsland) != nil {
            self.alwaysShowDynamicIsland = defaults.bool(forKey: AppSettingsKeys.alwaysShowDynamicIsland)
        } else {
            self.alwaysShowDynamicIsland = AppDefaults.alwaysShowDynamicIsland
        }
    }

    func autoDetectMethod() {
        guard let location = savedLocation else { return }
        selectedMethod = calculationService.recommendedMethod(for: location.timeZone)
    }

    func updateLocation(_ location: SavedLocation) {
        savedLocation = location
    }

    // MARK: - Persistence

    private func persistLocation() {
        guard let location = savedLocation,
              let data = try? JSONEncoder().encode(location) else {
            defaults.removeObject(forKey: AppSettingsKeys.savedLocation)
            return
        }
        defaults.set(data, forKey: AppSettingsKeys.savedLocation)
    }

    private func persistMethod() {
        defaults.set(selectedMethod.rawValue, forKey: AppSettingsKeys.calculationMethod)
    }

    private func persistMadhab() {
        defaults.set(selectedMadhab.rawValue, forKey: AppSettingsKeys.madhab)
    }

    private func persistNotificationMinutes() {
        defaults.set(notificationMinutesBefore, forKey: AppSettingsKeys.notificationMinutesBefore)
    }

    private func persistFloatingPanel() {
        defaults.set(showFloatingPanel, forKey: AppSettingsKeys.showFloatingPanel)
    }

    private func persistAlwaysShowDynamicIsland() {
        defaults.set(alwaysShowDynamicIsland, forKey: AppSettingsKeys.alwaysShowDynamicIsland)
    }
}
