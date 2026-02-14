import Foundation
import UserNotifications
import Adhan

@MainActor
final class NotificationService: ObservableObject {

    @Published var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func scheduleNotifications(
        for dailyTimes: DailyPrayerTimes,
        minutesBefore: Int,
        timeZone: TimeZone
    ) async {
        await cancelAllNotifications()

        guard isAuthorized, minutesBefore > 0 else { return }

        let prayersToNotify: [Prayer] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

        for prayer in prayersToNotify {
            guard let entry = dailyTimes.entry(for: prayer) else { continue }

            let notificationTime = entry.time.addingTimeInterval(-Double(minutesBefore * 60))

            guard notificationTime > Date() else { continue }

            var calendar = Calendar.current
            calendar.timeZone = timeZone
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: notificationTime
            )

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let content = UNMutableNotificationContent()
            content.title = "\(prayer.displayName) in \(minutesBefore) minutes"
            content.body = "Prayer time: \(entry.formattedTime)"
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "prayer-\(prayer.displayName.lowercased())",
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    func cancelAllNotifications() async {
        center.removeAllPendingNotificationRequests()
    }
}
