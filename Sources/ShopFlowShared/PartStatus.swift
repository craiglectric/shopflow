import Foundation

/// Dual-lifecycle part status (plan §2A — a SINGLE enum, not three columns).
/// Approval cycle (vendor pricing → customer quote) runs before the regular
/// fulfillment lifecycle for parts discovered mid-repair. Raw values are the
/// case names and must match iOS exactly.
public enum PartStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    // Approval cycle
    case pricingNeeded
    case pricingPending
    case quoteSent
    case quoteApproved
    case quoteDeclined
    // Fulfillment
    case needed
    case ordered
    case received
    case installed

    // Legacy — decode-only.
    case quoteNeeded
    case quotePending

    public var id: String { rawValue }

    public var normalized: PartStatus {
        switch self {
        case .quoteNeeded: return .pricingNeeded
        case .quotePending: return .quoteSent
        default: return self
        }
    }

    public var displayName: String {
        switch self {
        case .pricingNeeded:  return "Pricing Needed"
        case .pricingPending: return "Pricing Pending"
        case .quoteSent:      return "Quote Sent"
        case .quoteApproved:  return "Quote Approved"
        case .quoteDeclined:  return "Quote Declined"
        case .needed:         return "Needed"
        case .ordered:        return "Ordered"
        case .received:       return "Received"
        case .installed:      return "Installed"
        case .quoteNeeded:    return "Pricing Needed"   // legacy
        case .quotePending:   return "Quote Sent"        // legacy
        }
    }

    /// Per-part approval mini-flow (runs before fulfillment).
    public var isApprovalCycle: Bool {
        switch self {
        case .pricingNeeded, .pricingPending, .quoteSent, .quoteApproved, .quoteDeclined: return true
        case .needed, .ordered, .received, .installed: return false
        case .quoteNeeded, .quotePending: return true   // legacy
        }
    }

    /// Keeps the WO in Parts Ordered (still awaiting fulfillment). `quoteApproved`
    /// counts (authorized, not yet ordered); `quoteDeclined` does not.
    public var isOutstanding: Bool {
        switch self {
        case .pricingNeeded, .pricingPending, .quoteSent, .quoteApproved, .needed, .ordered: return true
        case .quoteDeclined, .received, .installed: return false
        case .quoteNeeded, .quotePending: return true   // legacy
        }
    }

    /// Doesn't block Parts Ordered → In Repair (received/installed/declined).
    public var isReadyForRepairStart: Bool {
        switch self {
        case .received, .installed, .quoteDeclined: return true
        case .pricingNeeded, .pricingPending, .quoteSent, .quoteApproved, .needed, .ordered: return false
        case .quoteNeeded, .quotePending: return false   // legacy
        }
    }

    /// Doesn't block In Repair → Ready for Pickup (only installed or declined).
    public var isCompletedForPickup: Bool {
        switch self {
        case .installed, .quoteDeclined: return true
        case .pricingNeeded, .pricingPending, .quoteSent, .quoteApproved, .needed, .ordered, .received: return false
        case .quoteNeeded, .quotePending: return false   // legacy
        }
    }
}
