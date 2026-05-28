import XCTest
@testable import ShopFlowShared

/// Port of the iOS `WorkOrderPartStateTests` pure-logic cases (the SwiftData
/// cascade-delete test stays on the iOS side — it's persistence, not logic).
final class WorkOrderStatusEngineTests: XCTestCase {

    private func part(_ status: PartStatus, shopInventory: Bool = false) -> PartSnapshot {
        PartSnapshot(isShopInventory: shopInventory, status: status)
    }

    // MARK: partsDrivenStatus

    func test_recompute_approvalCycleStatesAreOutstanding() {
        let result = WorkOrderStatusEngine.partsDrivenStatus(current: .inRepair, parts: [part(.pricingNeeded)])
        XCTAssertEqual(result, .partsOrdered)
    }

    func test_recompute_declinedDoesNotBlockBackToInRepair() {
        let result = WorkOrderStatusEngine.partsDrivenStatus(
            current: .partsOrdered, parts: [part(.quoteDeclined), part(.received)])
        XCTAssertEqual(result, .inRepair)
    }

    func test_recompute_ignoresShopInventory() {
        let result = WorkOrderStatusEngine.partsDrivenStatus(
            current: .inRepair, parts: [part(.needed, shopInventory: true)])
        XCTAssertEqual(result, .inRepair)
    }

    func test_recompute_quoteApprovedAdvancesWhenVendorPartOrdered() {
        let result = WorkOrderStatusEngine.partsDrivenStatus(current: .quoteApproved, parts: [part(.ordered)])
        XCTAssertEqual(result, .partsOrdered)
    }

    // MARK: canStartRepair / canCompleteRepair

    func test_canStartRepair_declinedPartsPass() {
        XCTAssertTrue(WorkOrderStatusEngine.canStartRepair([part(.quoteDeclined), part(.received)]))
    }

    func test_canStartRepair_approvalCycleBlocks() {
        XCTAssertFalse(WorkOrderStatusEngine.canStartRepair([part(.quoteSent)]))
    }

    func test_canCompleteRepair_declinedPartsPass() {
        XCTAssertTrue(WorkOrderStatusEngine.canCompleteRepair([part(.installed), part(.quoteDeclined)]))
    }

    func test_canCompleteRepair_receivedNotInstalledBlocks() {
        XCTAssertFalse(WorkOrderStatusEngine.canCompleteRepair([part(.received)]))
    }

    // MARK: auto-advance to Ready for Pickup

    private func advance(
        status: WorkOrderStatus,
        parts: [PartSnapshot],
        finalizedLabor: Bool = true,
        inProgressLabor: Bool = false,
        name: Bool = true,
        phone: Bool = true,
        assessment: Bool = true
    ) -> Bool {
        WorkOrderStatusEngine.shouldAutoAdvanceToReady(
            status: status, parts: parts,
            hasFinalizedLabor: finalizedLabor, hasInProgressLabor: inProgressLabor,
            customerNamePresent: name, customerPhonePresent: phone, assessmentComplete: assessment)
    }

    func test_autoAdvance_firesWhenAllPartsInstalledAndPreconditionsMet() {
        XCTAssertTrue(advance(status: .inRepair, parts: [part(.installed)]))
    }

    func test_autoAdvance_blockedWhenLaborMissing() {
        XCTAssertFalse(advance(status: .inRepair, parts: [part(.installed)], finalizedLabor: false))
    }

    func test_autoAdvance_blockedWhenTimerRunning() {
        XCTAssertFalse(advance(status: .inRepair, parts: [part(.installed)], inProgressLabor: true))
    }

    func test_autoAdvance_blockedWhenPartStillReceived() {
        XCTAssertFalse(advance(status: .inRepair, parts: [part(.received)]))
    }

    func test_autoAdvance_blockedWhenCustomerInfoMissing() {
        XCTAssertFalse(advance(status: .inRepair, parts: [part(.installed)], name: false))
    }

    func test_autoAdvance_doesNotFireFromOtherStatuses() {
        XCTAssertFalse(advance(status: .diagnosing, parts: [part(.installed)]))
    }

    func test_autoAdvance_declinedPartsCountAsCompleted() {
        XCTAssertTrue(advance(status: .inRepair, parts: [part(.installed), part(.quoteDeclined)]))
    }

    // MARK: awaitingPartsInstallation

    func test_awaitingPartsInstallation_falseWhenOneVendorPartStillEnroute() {
        XCTAssertFalse(WorkOrderStatusEngine.awaitingPartsInstallation(
            status: .partsOrdered, parts: [part(.received), part(.ordered)]))
    }

    func test_awaitingPartsInstallation_trueWhenAllReceived() {
        XCTAssertTrue(WorkOrderStatusEngine.awaitingPartsInstallation(
            status: .partsOrdered, parts: [part(.received), part(.received)]))
    }

    func test_awaitingPartsInstallation_falseWhenAllInstalled() {
        XCTAssertFalse(WorkOrderStatusEngine.awaitingPartsInstallation(
            status: .inRepair, parts: [part(.installed)]))
    }

    func test_awaitingPartsInstallation_falseForLaborOnlyWO() {
        XCTAssertFalse(WorkOrderStatusEngine.awaitingPartsInstallation(status: .inRepair, parts: []))
    }

    func test_awaitingPartsInstallation_ignoresDeclinedParts() {
        XCTAssertTrue(WorkOrderStatusEngine.awaitingPartsInstallation(
            status: .partsOrdered, parts: [part(.received), part(.quoteDeclined)]))
    }

    // MARK: declineOutstandingParts

    func test_declineOutstandingParts_flipsPreCommitmentStates() {
        let flips: [PartStatus] = [.needed, .pricingNeeded, .pricingPending, .quoteSent, .quoteApproved]
        for s in flips {
            XCTAssertEqual(WorkOrderStatusEngine.statusAfterWorkOrderDeclined(s), .quoteDeclined, "\(s)")
        }
        let kept: [PartStatus] = [.ordered, .received, .installed, .quoteDeclined]
        for s in kept {
            XCTAssertEqual(WorkOrderStatusEngine.statusAfterWorkOrderDeclined(s), s, "\(s)")
        }
    }

    // MARK: hasVendorParts

    func test_hasVendorParts_falseForLaborOnly() {
        XCTAssertFalse(WorkOrderStatusEngine.hasVendorParts([]))
    }

    func test_hasVendorParts_falseForShopInventoryOnly() {
        XCTAssertFalse(WorkOrderStatusEngine.hasVendorParts([part(.needed, shopInventory: true)]))
    }

    func test_hasVendorParts_trueWithAnyVendorPart() {
        XCTAssertTrue(WorkOrderStatusEngine.hasVendorParts([
            part(.needed, shopInventory: true), part(.needed, shopInventory: false)]))
    }
}
