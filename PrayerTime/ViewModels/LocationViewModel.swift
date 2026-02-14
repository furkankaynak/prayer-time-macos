import Foundation
import Combine

@MainActor
final class LocationViewModel: ObservableObject {

    @Published var searchText: String = ""
    @Published var searchResults: [LocationSearchResult] = []
    @Published var isSearching = false

    private let locationService: LocationService
    private let settingsViewModel: SettingsViewModel
    private let calculationService = PrayerCalculationService()

    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    init(locationService: LocationService, settingsViewModel: SettingsViewModel) {
        self.locationService = locationService
        self.settingsViewModel = settingsViewModel

        setupSearchDebounce()
    }

    // MARK: - Search

    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }

    private func performSearch(query: String) {
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            let results = await locationService.searchLocations(query: query)
            guard !Task.isCancelled else { return }
            searchResults = results
            isSearching = false
        }
    }

    // MARK: - Location Detection

    var isLocating: Bool { locationService.isLocating }
    var locationError: String? { locationService.locationError }
    var isLocationDenied: Bool {
        locationService.authorizationStatus == .denied ||
        locationService.authorizationStatus == .restricted
    }

    func detectLocation() {
        locationService.requestLocation()

        // Observe when currentLocation is set by LocationService
        locationService.$currentLocation
            .compactMap { $0 }
            .first()
            .sink { [weak self] result in
                self?.selectResult(result)
            }
            .store(in: &cancellables)
    }

    // MARK: - Selection

    func selectResult(_ result: LocationSearchResult) {
        let saved = result.toSavedLocation()
        settingsViewModel.updateLocation(saved)
        settingsViewModel.autoDetectMethod()
        searchText = ""
        searchResults = []
    }
}
