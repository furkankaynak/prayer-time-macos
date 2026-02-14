import Foundation
import Adhan

struct PrayerCalculationService {

    func calculatePrayerTimes(
        for location: SavedLocation,
        on date: Date = Date(),
        method: CalculationMethodOption,
        madhab: MadhabOption
    ) -> DailyPrayerTimes? {
        var cal = Calendar.current
        cal.timeZone = location.timeZone

        let components = cal.dateComponents([.year, .month, .day], from: date)

        var params = method.adhanMethod.params
        params.madhab = madhab.adhanMadhab
        params.highLatitudeRule = HighLatitudeRule.recommended(for: location.coordinates)

        guard let prayerTimes = PrayerTimes(
            coordinates: location.coordinates,
            date: components,
            calculationParameters: params
        ) else {
            return nil
        }

        return DailyPrayerTimes(from: prayerTimes)
    }

    func recommendedMethod(for timeZone: TimeZone) -> CalculationMethodOption {
        let id = timeZone.identifier

        if id.hasPrefix("America/") {
            return .northAmerica
        }
        if id.hasPrefix("Europe/Istanbul") || id.hasPrefix("Asia/Istanbul") {
            return .turkey
        }
        if id.hasPrefix("Europe/") {
            return .muslimWorldLeague
        }
        if id.hasPrefix("Asia/Riyadh") || id.hasPrefix("Asia/Aden") {
            return .ummAlQura
        }
        if id.hasPrefix("Asia/Dubai") || id.hasPrefix("Asia/Muscat") {
            return .dubai
        }
        if id.hasPrefix("Asia/Kuwait") {
            return .kuwait
        }
        if id.hasPrefix("Asia/Qatar") || id.hasPrefix("Asia/Bahrain") {
            return .qatar
        }
        if id.hasPrefix("Asia/Tehran") {
            return .tehran
        }
        if id.hasPrefix("Asia/Karachi") || id.hasPrefix("Asia/Kolkata") || id.hasPrefix("Asia/Dhaka") {
            return .karachi
        }
        if id.hasPrefix("Asia/Singapore") || id.hasPrefix("Asia/Kuala_Lumpur") || id.hasPrefix("Asia/Jakarta") {
            return .singapore
        }
        if id.hasPrefix("Africa/Cairo") {
            return .egyptian
        }
        if id.hasPrefix("Africa/") {
            return .muslimWorldLeague
        }

        return .muslimWorldLeague
    }
}
