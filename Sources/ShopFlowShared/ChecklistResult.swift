import Foundation

/// Outcome of a single assessment-checklist item. On disk it's a raw string
/// (`result_raw`): "" / "pass" / "fail" / "na" — matching the iOS storage
/// mapping exactly so data round-trips.
public enum ChecklistResult: String, Codable, CaseIterable, Sendable {
    case unset
    case pass
    case fail
    case notApplicable

    public var storageValue: String {
        switch self {
        case .unset:          return ""
        case .pass:           return "pass"
        case .fail:           return "fail"
        case .notApplicable:  return "na"
        }
    }

    public static func from(storage: String) -> ChecklistResult {
        switch storage {
        case "pass": return .pass
        case "fail": return .fail
        case "na":   return .notApplicable
        default:     return .unset
        }
    }

    public var displayName: String {
        switch self {
        case .unset:          return "Not Set"
        case .pass:           return "Pass"
        case .fail:           return "Fail"
        case .notApplicable:  return "N/A"
        }
    }
}
