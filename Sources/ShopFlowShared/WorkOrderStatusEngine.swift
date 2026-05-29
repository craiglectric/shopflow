import Foundation

/// A part's state as far as the status machine cares — decoupled from any
/// storage model so the engine is pure and shared by client + server.
public struct PartSnapshot: Sendable, Equatable {
    public let isShopInventory: Bool
    public let status: PartStatus

    public init(isShopInventory: Bool, status: PartStatus) {
        self.isShopInventory = isShopInventory
        self.status = status
    }
}

/// Pure port of the iOS WorkOrder ↔ PartLine state-machine logic
/// (`recomputePartsDrivenStatus`, `recomputeRepairCompletionStatus`,
/// `canStartRepair`, `canCompleteRepair`, `awaitingPartsInstallation`,
/// `declineOutstandingParts`, `hasVendorParts`). The server calls these from its
/// CRUD handlers; iOS will call the same code at M6. No persistence, no I/O.
public enum WorkOrderStatusEngine {

    /// Any non-shop-inventory part (something that must be ordered from a vendor).
    public static func hasVendorParts(_ parts: [PartSnapshot]) -> Bool {
        parts.contains { !$0.isShopInventory }
    }

    /// Parts Ordered → In Repair gate: every vendor part received/installed/declined.
    /// Shop-inventory parts are excluded (they sit at Needed until installed).
    public static func canStartRepair(_ parts: [PartSnapshot]) -> Bool {
        parts.allSatisfy { $0.isShopInventory || $0.status.isReadyForRepairStart }
    }

    /// In Repair → Ready for Pickup gate: every part installed or declined
    /// (shop-inventory included — those are the fasteners actually fitted).
    public static func canCompleteRepair(_ parts: [PartSnapshot]) -> Bool {
        parts.allSatisfy { $0.status.isCompletedForPickup }
    }

    /// The "Ready to Repair" bench signal: in the repair phase, with vendor
    /// parts present, all settled, and at least one freshly received.
    public static func awaitingPartsInstallation(status: WorkOrderStatus, parts: [PartSnapshot]) -> Bool {
        guard status == .inRepair || status == .partsOrdered else { return false }
        let vendorParts = parts.filter { !$0.isShopInventory }
        guard !vendorParts.isEmpty else { return false }
        let allSettled = vendorParts.allSatisfy {
            $0.status == .received || $0.status == .installed || $0.status == .quoteDeclined
        }
        let anyAwaitingInstall = vendorParts.contains { $0.status == .received }
        return allSettled && anyAwaitingInstall
    }

    /// Auto-flip between `.inRepair` and `.partsOrdered` from part state, and the
    /// forward `.quoteApproved` → `.partsOrdered` nudge once a vendor part is
    /// ordered. Returns the (possibly unchanged) status. Idempotent.
    public static func partsDrivenStatus(current: WorkOrderStatus, parts: [PartSnapshot]) -> WorkOrderStatus {
        var status = current

        if status == .quoteApproved {
            let anyAdvanced = parts.contains {
                !$0.isShopInventory &&
                ($0.status == .ordered || $0.status == .received || $0.status == .installed)
            }
            if anyAdvanced { status = .partsOrdered }
        }

        guard status == .inRepair || status == .partsOrdered else { return status }
        let hasOutstanding = parts.contains { !$0.isShopInventory && $0.status.isOutstanding }
        return hasOutstanding ? .partsOrdered : .inRepair
    }

    /// Whether In Repair should auto-advance to Ready for Pickup. The
    /// labor/customer/assessment preconditions are computed by the caller (they
    /// require the WO's children) and passed in. Mirrors iOS
    /// `recomputeRepairCompletionStatus`.
    public static func shouldAutoAdvanceToReady(
        status: WorkOrderStatus,
        parts: [PartSnapshot],
        hasFinalizedLabor: Bool,
        hasInProgressLabor: Bool,
        customerNamePresent: Bool,
        customerPhonePresent: Bool,
        assessmentComplete: Bool
    ) -> Bool {
        guard status == .inRepair else { return false }
        guard canCompleteRepair(parts) else { return false }
        guard hasFinalizedLabor else { return false }
        guard !hasInProgressLabor else { return false }
        guard customerNamePresent, customerPhonePresent else { return false }
        guard assessmentComplete else { return false }
        return true
    }

    /// Whether the 8-point assessment checklist is complete for a WO of the
    /// given device type. Pure port of iOS `WorkOrder.isAssessmentChecklistComplete`:
    /// every item the device's template expects must be resolved (Pass,
    /// Fail-with-note, or N/A); for optional sections, a section-level marker row
    /// (`itemKey == ""`, `result == .notApplicable`) satisfies the whole section.
    /// An untouched item has no snapshot at all and reads as unresolved.
    public static func isAssessmentComplete(
        device: DeviceType?,
        states: [ChecklistItemSnapshot]
    ) -> Bool {
        let template = ChecklistTemplate.forDevice(device)
        for section in template.sections {
            if section.isOptional {
                let marker = states.first { $0.sectionKey == section.key && $0.isSectionMarker }
                if marker?.result == .notApplicable { continue }
            }
            for item in section.items {
                let state = states.first {
                    $0.sectionKey == section.key && $0.itemKey == item.key
                }
                guard let state, state.isResolved else { return false }
            }
        }
        return true
    }

    /// When a WO is declined, pre-commitment parts (Needed or anywhere in the
    /// approval cycle) are flipped to declined; already-ordered-and-beyond parts
    /// are commitments the shop made and are left alone.
    public static func statusAfterWorkOrderDeclined(_ status: PartStatus) -> PartStatus {
        switch status {
        case .needed, .pricingNeeded, .pricingPending, .quoteSent, .quoteApproved:
            return .quoteDeclined
        default:
            return status
        }
    }
}
