import Foundation
import Adhan

// MARK: - Prayer Extension

extension Prayer: @retroactive Identifiable {
    public var id: Self { self }

    var displayName: String {
        switch self {
        case .fajr: return "Fajr"
        case .sunrise: return "Sunrise"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }

    var sfSymbol: String {
        switch self {
        case .fajr: return "sunrise.fill"
        case .sunrise: return "sun.horizon.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.and.horizon.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        }
    }
}

// MARK: - Prayer Time Entry

struct PrayerTimeEntry: Identifiable {
    let prayer: Prayer
    let time: Date

    var id: Prayer { prayer }
    var displayName: String { prayer.displayName }
    var sfSymbol: String { prayer.sfSymbol }

    var formattedTime: String {
        Self.timeFormatter.string(from: time)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Daily Prayer Times

struct DailyPrayerTimes {
    let date: Date
    let entries: [PrayerTimeEntry]
    let sunrise: Date
    let sunset: Date
    let adhanPrayerTimes: PrayerTimes

    init(from prayerTimes: PrayerTimes) {
        self.adhanPrayerTimes = prayerTimes
        self.sunrise = prayerTimes.sunrise
        self.sunset = prayerTimes.maghrib

        var cal = Calendar.current
        if let tz = prayerTimes.date.timeZone {
            cal.timeZone = tz
        }
        self.date = cal.startOfDay(for: prayerTimes.fajr)

        self.entries = Prayer.allCases.map { prayer in
            PrayerTimeEntry(prayer: prayer, time: prayerTimes.time(for: prayer))
        }
    }

    func entry(for prayer: Prayer) -> PrayerTimeEntry? {
        entries.first { $0.prayer == prayer }
    }

    func currentPrayer(at time: Date = Date()) -> Prayer? {
        adhanPrayerTimes.currentPrayer(at: time)
    }

    func nextPrayer(at time: Date = Date()) -> Prayer? {
        adhanPrayerTimes.nextPrayer(at: time)
    }
}
