import Foundation

/// Orders Log Book entries not tied to an in-shop work order.
public enum SpecialOrderKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case customerSpecialOrder
    case fieldWorkPart

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .customerSpecialOrder: return "Customer Special Order"
        case .fieldWorkPart:        return "Field Work Part"
        }
    }

    public var badgeLabel: String {
        switch self {
        case .customerSpecialOrder: return "Special Order"
        case .fieldWorkPart:        return "Field Work"
        }
    }

    /// Field-work entries get an `installScheduled` step; counter pickups skip it.
    public var allowsInstallScheduling: Bool {
        self == .fieldWorkPart
    }
}

public enum SpecialOrderStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case needed
    case ordered
    case received
    case customerContacted
    case installScheduled
    case completed

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .needed:             return "Needed"
        case .ordered:            return "Ordered"
        case .received:           return "Received"
        case .customerContacted:  return "Customer Contacted"
        case .installScheduled:   return "Install Scheduled"
        case .completed:          return "Completed"
        }
    }
}
