import Foundation

/// Canonical work-order status vocabulary. Raw values are the case names and
/// MUST match the iOS app exactly — they round-trip through the sync protocol
/// and the Denver data migration (M11). Legacy cases are kept so old records
/// still decode; a migrator rewrites them (`quotePending`→`quoteSent`,
/// `qcTesting`→`inRepair`).
public enum WorkOrderStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case checkedIn
    case diagnosing
    case awaitingPricing
    case quoteSent
    case quoteApproved
    case quoteDeclined
    case partsOrdered
    case inRepair
    case readyForPickup
    case pickedUp

    // Legacy — decode-only; rewritten by the migrator.
    case quotePending
    case qcTesting

    public var id: String { rawValue }

    /// Canonicalizes a legacy case to its modern equivalent (the server-side
    /// equivalent of iOS `WorkOrder.migrateLegacyStatuses`).
    public var normalized: WorkOrderStatus {
        switch self {
        case .quotePending: return .quoteSent
        case .qcTesting: return .inRepair
        default: return self
        }
    }

    public var displayName: String {
        switch self {
        case .checkedIn:        return "Checked In"
        case .diagnosing:       return "Diagnosing"
        case .awaitingPricing:  return "Awaiting Pricing"
        case .quoteSent:        return "Quote Sent"
        case .quoteApproved:    return "Quote Approved"
        case .quoteDeclined:    return "Quote Declined"
        case .partsOrdered:     return "Parts Ordered"
        case .inRepair:         return "In Repair"
        case .readyForPickup:   return "Ready for Pickup"
        case .pickedUp:         return "Picked Up"
        case .quotePending:     return "Quote Sent"   // legacy
        case .qcTesting:        return "In Repair"    // legacy
        }
    }

    /// Allowed forward transitions. Picked Up is terminal and only reached via
    /// the checkout flow, so it's not exposed as a manual destination.
    public var allowedTransitions: [WorkOrderStatus] {
        switch self {
        case .checkedIn:        return [.diagnosing, .quoteDeclined]
        case .diagnosing:       return [.quoteApproved, .quoteDeclined, .quoteSent, .awaitingPricing, .inRepair]
        case .awaitingPricing:  return [.quoteApproved, .quoteDeclined, .quoteSent, .diagnosing]
        case .quoteSent:        return [.quoteApproved, .quoteDeclined]
        case .quoteApproved:    return [.partsOrdered, .inRepair]
        case .quoteDeclined:    return [.readyForPickup]
        case .partsOrdered:     return [.inRepair, .quoteDeclined]
        case .inRepair:         return [.readyForPickup]
        case .readyForPickup:   return []
        case .pickedUp:         return []
        case .quotePending:     return [.quoteApproved, .quoteDeclined]   // legacy
        case .qcTesting:        return [.readyForPickup, .inRepair]       // legacy
        }
    }

    /// Whether a manual move from `self` to `target` is permitted.
    public func canTransition(to target: WorkOrderStatus) -> Bool {
        allowedTransitions.contains(target)
    }
}
