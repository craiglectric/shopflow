import XCTest
@testable import ShopFlowShared

final class ChecklistResultTests: XCTestCase {

    func testStorageRoundTrip() {
        for result in ChecklistResult.allCases {
            XCTAssertEqual(ChecklistResult.from(storage: result.storageValue), result)
        }
    }

    func testStorageValuesMatchIOS() {
        XCTAssertEqual(ChecklistResult.unset.storageValue, "")
        XCTAssertEqual(ChecklistResult.pass.storageValue, "pass")
        XCTAssertEqual(ChecklistResult.fail.storageValue, "fail")
        XCTAssertEqual(ChecklistResult.notApplicable.storageValue, "na")
    }

    func testUnknownStorageDefaultsToUnset() {
        XCTAssertEqual(ChecklistResult.from(storage: "garbage"), .unset)
        XCTAssertEqual(ChecklistResult.from(storage: ""), .unset)
    }
}
