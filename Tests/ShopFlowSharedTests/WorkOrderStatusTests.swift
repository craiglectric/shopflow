import XCTest
@testable import ShopFlowShared

final class WorkOrderStatusTests: XCTestCase {

    func testTerminalStatesHaveNoTransitions() {
        XCTAssertTrue(WorkOrderStatus.readyForPickup.allowedTransitions.isEmpty)
        XCTAssertTrue(WorkOrderStatus.pickedUp.allowedTransitions.isEmpty)
    }

    func testDiagnosingFansOut() {
        let from = WorkOrderStatus.diagnosing.allowedTransitions
        XCTAssertEqual(Set(from), [.quoteApproved, .quoteDeclined, .quoteSent, .awaitingPricing, .inRepair])
    }

    func testQuoteApprovedLeadsToOrderingOrRepair() {
        XCTAssertEqual(Set(WorkOrderStatus.quoteApproved.allowedTransitions), [.partsOrdered, .inRepair])
    }

    func testCanTransitionHelper() {
        XCTAssertTrue(WorkOrderStatus.checkedIn.canTransition(to: .diagnosing))
        XCTAssertFalse(WorkOrderStatus.checkedIn.canTransition(to: .pickedUp))
        XCTAssertFalse(WorkOrderStatus.inRepair.canTransition(to: .checkedIn))
    }

    func testLegacyNormalization() {
        XCTAssertEqual(WorkOrderStatus.quotePending.normalized, .quoteSent)
        XCTAssertEqual(WorkOrderStatus.qcTesting.normalized, .inRepair)
        XCTAssertEqual(WorkOrderStatus.inRepair.normalized, .inRepair)
    }

    func testRawValuesAreStableCaseNames() {
        XCTAssertEqual(WorkOrderStatus.checkedIn.rawValue, "checkedIn")
        XCTAssertEqual(WorkOrderStatus.readyForPickup.rawValue, "readyForPickup")
    }
}
