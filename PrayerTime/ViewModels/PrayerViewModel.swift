import Foundation
import Combine
import Adhan
import AppKit

@MainActor
final class PrayerViewModel: ObservableObject {

    // MARK: - Published State

    @Published var todayTimes: DailyPrayerTimes?
    @Published var tomorrowTimes: DailyPrayerTimes?
    @Published var currentPrayer: Prayer?
    @Published var nextPrayer: Prayer?
    @Published var nextPrayerTime: Date?
    @Published var countdownText: String = ""
    @Published var menuBarText: String = "Prayer Time"
    @Published var menuBarSymbol: String = "sun.max.fill"
    @Published var sunProgress: Double = 0.0
    @Published var shouldShowFloatingPanel = false

    // MARK: - Dependencies

    private let calculationService = PrayerCalculationService()
    private let settingsViewModel: SettingsViewModel
    private let notificationService: NotificationService

    private var cancellables = Set<AnyCancellable>()
    private var timer: AnyCancellable?
    private var lastCalculationDate: Date?

    // MARK: - Init

    init(settingsViewModel: SettingsViewModel, notificationService: NotificationService) {
        self.settingsViewModel = settingsViewModel
        self.notificationService = notificationService

        observeSettings()
        startTimer()
        observeWakeFromSleep()
        recalculate()
    }

    // MARK: - Observation

    private func observeSettings() {
        settingsViewModel.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                // Defer to next runloop tick so published values are updated
                Task { @MainActor [weak self] in
                    self?.recalculate()
                }
            }
            .store(in: &cancellables)
    }

    private func observeWakeFromSleep() {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didWakeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.recalculate()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCurrentState()
            }
    }

    // MARK: - Calculation

    func recalculate() {
        guard let location = settingsViewModel.savedLocation else {
            todayTimes = nil
            tomorrowTimes = nil
            updateCurrentState()
            return
        }

        let method = settingsViewModel.selectedMethod
        let madhab = settingsViewModel.selectedMadhab
        let now = Date()

        todayTimes = calculationService.calculatePrayerTimes(
            for: location, on: now, method: method, madhab: madhab
        )

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        tomorrowTimes = calculationService.calculatePrayerTimes(
            for: location, on: tomorrow, method: method, madhab: madhab
        )

        lastCalculationDate = now
        updateCurrentState()
        scheduleNotifications()
    }

    // MARK: - State Update

    private func updateCurrentState() {
        let now = Date()

        // Check for midnight recalculation
        if let lastDate = lastCalculationDate,
           !Calendar.current.isDate(lastDate, inSameDayAs: now) {
            recalculate()
            return
        }

        guard let today = todayTimes else {
            currentPrayer = nil
            nextPrayer = nil
            nextPrayerTime = nil
            countdownText = ""
            menuBarText = "No Location"
            menuBarSymbol = "location.slash"
            sunProgress = 0.0
            return
        }

        currentPrayer = today.currentPrayer(at: now)
        let next = today.nextPrayer(at: now)

        // After Isha: next prayer is tomorrow's Fajr
        if next == nil {
            nextPrayer = .fajr
            nextPrayerTime = tomorrowTimes?.entry(for: .fajr)?.time
        } else {
            nextPrayer = next
            nextPrayerTime = next.flatMap { today.entry(for: $0)?.time }
        }

        // Countdown
        if let target = nextPrayerTime {
            countdownText = formatCountdown(from: now, to: target)
        } else {
            countdownText = ""
        }

        // Menu bar
        if let prayer = nextPrayer, let time = nextPrayerTime {
            let timeStr = shortTimeFormatter.string(from: time)
            menuBarText = "\(prayer.displayName) \(timeStr)"
            menuBarSymbol = prayer.sfSymbol
        } else if let prayer = currentPrayer {
            menuBarSymbol = prayer.sfSymbol
            menuBarText = prayer.displayName
        }

        // Sun progress (sunrise to sunset)
        updateSunProgress(now: now, today: today)

        // Floating panel trigger
        checkFloatingPanelTrigger(now: now)
    }

    private func updateSunProgress(now: Date, today: DailyPrayerTimes) {
        let sunrise = today.sunrise
        let sunset = today.sunset

        if now < sunrise {
            sunProgress = 0.0
        } else if now > sunset {
            sunProgress = 1.0
        } else {
            let total = sunset.timeIntervalSince(sunrise)
            let elapsed = now.timeIntervalSince(sunrise)
            sunProgress = total > 0 ? elapsed / total : 0.0
        }
    }

    // MARK: - Floating Panel

    private var floatingPanelShownForPrayer: Prayer?

    private func checkFloatingPanelTrigger(now: Date) {
        guard settingsViewModel.showFloatingPanel,
              let prayer = nextPrayer,
              let time = nextPrayerTime else {
            shouldShowFloatingPanel = false
            return
        }

        if settingsViewModel.alwaysShowDynamicIsland {
            shouldShowFloatingPanel = true
            return
        }

        let minutesBefore = Double(settingsViewModel.notificationMinutesBefore)
        let triggerTime = time.addingTimeInterval(-minutesBefore * 60)

        if now >= triggerTime && now < time && floatingPanelShownForPrayer != prayer {
            shouldShowFloatingPanel = true
            floatingPanelShownForPrayer = prayer
        } else if now >= time {
            shouldShowFloatingPanel = false
        } else {
            shouldShowFloatingPanel = false
        }
    }

    func dismissFloatingPanel() {
        shouldShowFloatingPanel = false
    }

    // MARK: - Notifications

    private func scheduleNotifications() {
        guard let today = todayTimes,
              let location = settingsViewModel.savedLocation else { return }

        Task {
            await notificationService.checkAuthorizationStatus()
            await notificationService.scheduleNotifications(
                for: today,
                minutesBefore: settingsViewModel.notificationMinutesBefore,
                timeZone: location.timeZone
            )
        }
    }

    // MARK: - Formatting

    private func formatCountdown(from: Date, to: Date) -> String {
        let interval = Int(to.timeIntervalSince(from))
        guard interval > 0 else { return "" }

        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    private let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}
