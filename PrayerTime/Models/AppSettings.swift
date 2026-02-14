import Foundation
import Adhan

// MARK: - UserDefaults Keys

struct AppSettingsKeys {
    static let savedLocation = "savedLocation"
    static let calculationMethod = "calculationMethod"
    static let madhab = "madhab"
    static let notificationMinutesBefore = "notificationMinutesBefore"
    static let showFloatingPanel = "showFloatingPanel"

    private init() {}
}

// MARK: - Calculation Method

enum CalculationMethodOption: String, Codable, CaseIterable, Identifiable {
    case muslimWorldLeague
    case egyptian
    case karachi
    case ummAlQura
    case dubai
    case moonsightingCommittee
    case northAmerica
    case kuwait
    case qatar
    case singapore
    case tehran
    case turkey

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .muslimWorldLeague: return "Muslim World League"
        case .egyptian: return "Egyptian General Authority"
        case .karachi: return "University of Islamic Sciences, Karachi"
        case .ummAlQura: return "Umm al-Qura University, Makkah"
        case .dubai: return "Dubai"
        case .moonsightingCommittee: return "Moonsighting Committee"
        case .northAmerica: return "ISNA (North America)"
        case .kuwait: return "Kuwait"
        case .qatar: return "Qatar"
        case .singapore: return "Singapore"
        case .tehran: return "Institute of Geophysics, Tehran"
        case .turkey: return "Diyanet, Turkey"
        }
    }

    var adhanMethod: CalculationMethod {
        switch self {
        case .muslimWorldLeague: return .muslimWorldLeague
        case .egyptian: return .egyptian
        case .karachi: return .karachi
        case .ummAlQura: return .ummAlQura
        case .dubai: return .dubai
        case .moonsightingCommittee: return .moonsightingCommittee
        case .northAmerica: return .northAmerica
        case .kuwait: return .kuwait
        case .qatar: return .qatar
        case .singapore: return .singapore
        case .tehran: return .tehran
        case .turkey: return .turkey
        }
    }

    init?(from method: CalculationMethod) {
        switch method {
        case .muslimWorldLeague: self = .muslimWorldLeague
        case .egyptian: self = .egyptian
        case .karachi: self = .karachi
        case .ummAlQura: self = .ummAlQura
        case .dubai: self = .dubai
        case .moonsightingCommittee: self = .moonsightingCommittee
        case .northAmerica: self = .northAmerica
        case .kuwait: self = .kuwait
        case .qatar: self = .qatar
        case .singapore: self = .singapore
        case .tehran: self = .tehran
        case .turkey: self = .turkey
        case .other: return nil
        }
    }
}

// MARK: - Madhab

enum MadhabOption: String, Codable, CaseIterable, Identifiable {
    case shafi
    case hanafi

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shafi: return "Shafi / Maliki / Hanbali"
        case .hanafi: return "Hanafi"
        }
    }

    var adhanMadhab: Madhab {
        switch self {
        case .shafi: return .shafi
        case .hanafi: return .hanafi
        }
    }
}

// MARK: - Defaults

struct AppDefaults {
    static let calculationMethod: CalculationMethodOption = .muslimWorldLeague
    static let madhab: MadhabOption = .shafi
    static let notificationMinutesBefore: Int = 15
    static let showFloatingPanel: Bool = true

    private init() {}
}
