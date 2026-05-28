import Foundation

/// Equipment on the bench. iOS-only presentation (asset names, SF Symbol
/// fallbacks, common-issue chips) lives in an iOS-side extension; the shared
/// type carries the canonical cases + cross-platform logic.
public enum DeviceType: String, Codable, CaseIterable, Identifiable, Sendable {
    case scooter
    case powerChair
    case complexPowerChair
    case rollator
    case walker
    case cane
    case liftChair
    case bed
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .scooter:           return "Scooter"
        case .powerChair:        return "Power Chair"
        case .complexPowerChair: return "Complex Power Chair"
        case .rollator:          return "Rollator"
        case .walker:            return "Walker"
        case .cane:              return "Cane"
        case .liftChair:         return "Lift Chair"
        case .bed:               return "Bed"
        case .other:             return "Other"
        }
    }

    /// Ships with a charger that may or may not be dropped off — drives the
    /// "charger included?" intake prompt.
    public var isPowered: Bool {
        switch self {
        case .scooter, .powerChair, .complexPowerChair: return true
        case .rollator, .walker, .cane, .liftChair, .bed, .other: return false
        }
    }
}
