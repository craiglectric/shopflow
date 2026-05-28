import XCTest
@testable import ShopFlowShared

final class PartStatusTests: XCTestCase {

    func testApprovalCyclePartition() {
        let approval: Set<PartStatus> = [.pricingNeeded, .pricingPending, .quoteSent, .quoteApproved, .quoteDeclined]
        let fulfillment: Set<PartStatus> = [.needed, .ordered, .received, .installed]
        for s in approval { XCTAssertTrue(s.isApprovalCycle, "\(s) should be approval-cycle") }
        for s in fulfillment { XCTAssertFalse(s.isApprovalCycle, "\(s) should not be approval-cycle") }
    }

    func testOutstandingKeepsWOInPartsOrdered() {
        // Authorized-but-not-fulfilled states are outstanding; declined and
        // received/installed are not.
        let outstanding: Set<PartStatus> = [.pricingNeeded, .pricingPending, .quoteSent, .quoteApproved, .needed, .ordered]
        let settled: Set<PartStatus> = [.quoteDeclined, .received, .installed]
        for s in outstanding { XCTAssertTrue(s.isOutstanding, "\(s) should be outstanding") }
        for s in settled { XCTAssertFalse(s.isOutstanding, "\(s) should not be outstanding") }
    }

    func testReadyForRepairStart() {
        for s in [PartStatus.received, .installed, .quoteDeclined] {
            XCTAssertTrue(s.isReadyForRepairStart, "\(s)")
        }
        for s in [PartStatus.pricingNeeded, .pricingPending, .quoteSent, .quoteApproved, .needed, .ordered] {
            XCTAssertFalse(s.isReadyForRepairStart, "\(s)")
        }
    }

    func testCompletedForPickupOnlyInstalledOrDeclined() {
        for s in [PartStatus.installed, .quoteDeclined] {
            XCTAssertTrue(s.isCompletedForPickup, "\(s)")
        }
        // received is NOT completed-for-pickup — it still needs installing.
        for s in [PartStatus.pricingNeeded, .pricingPending, .quoteSent, .quoteApproved, .needed, .ordered, .received] {
            XCTAssertFalse(s.isCompletedForPickup, "\(s)")
        }
    }

    func testLegacyNormalization() {
        XCTAssertEqual(PartStatus.quoteNeeded.normalized, .pricingNeeded)
        XCTAssertEqual(PartStatus.quotePending.normalized, .quoteSent)
        XCTAssertEqual(PartStatus.needed.normalized, .needed)
    }

    func testRawValuesAreStableCaseNames() {
        // These strings are persisted + synced; guard against accidental renames.
        XCTAssertEqual(PartStatus.pricingNeeded.rawValue, "pricingNeeded")
        XCTAssertEqual(PartStatus.quoteApproved.rawValue, "quoteApproved")
        XCTAssertEqual(PartStatus.installed.rawValue, "installed")
    }
}
