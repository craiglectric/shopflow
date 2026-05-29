import XCTest
@testable import ShopFlowShared

/// Port of the iOS `WorkOrder.isAssessmentChecklistComplete` cases. Mirrors the
/// rule exactly: every template item must be resolved (Pass / Fail-with-note /
/// N/A), and an optional section can be satisfied wholesale by a section-level
/// `.notApplicable` marker row (`itemKey == ""`).
final class AssessmentChecklistTests: XCTestCase {

    private func item(
        _ section: String,
        _ key: String,
        _ result: ChecklistResult,
        note: String? = nil
    ) -> ChecklistItemSnapshot {
        ChecklistItemSnapshot(sectionKey: section, itemKey: key, result: result, failureNote: note)
    }

    /// Every item of a template marked Pass — the all-resolved happy path.
    private func allPass(_ template: ChecklistTemplate) -> [ChecklistItemSnapshot] {
        template.sections.flatMap { section in
            section.items.map { item(section.key, $0.key, .pass) }
        }
    }

    // MARK: ChecklistItemSnapshot.isResolved

    func test_isResolved_passAndNA() {
        XCTAssertTrue(item("s", "i", .pass).isResolved)
        XCTAssertTrue(item("s", "i", .notApplicable).isResolved)
    }

    func test_isResolved_unsetIsUnresolved() {
        XCTAssertFalse(item("s", "i", .unset).isResolved)
    }

    func test_isResolved_failNeedsNonEmptyNote() {
        XCTAssertFalse(item("s", "i", .fail).isResolved)
        XCTAssertFalse(item("s", "i", .fail, note: "   ").isResolved)
        XCTAssertTrue(item("s", "i", .fail, note: "corroded").isResolved)
    }

    // MARK: isAssessmentComplete

    func test_complete_emptyStatesIsIncomplete() {
        XCTAssertFalse(WorkOrderStatusEngine.isAssessmentComplete(device: .scooter, states: []))
    }

    func test_complete_allItemsPass() {
        let states = allPass(.mobilityScooter)
        XCTAssertTrue(WorkOrderStatusEngine.isAssessmentComplete(device: .scooter, states: states))
    }

    func test_complete_oneUnsetItemBlocks() {
        var states = allPass(.mobilityScooter)
        states.removeLast() // drop one item → unresolved
        XCTAssertFalse(WorkOrderStatusEngine.isAssessmentComplete(device: .scooter, states: states))
    }

    func test_complete_failWithoutNoteBlocks() {
        var states = allPass(.mobilityScooter)
        // Flip the first item to an unnoted failure.
        let first = states[0]
        states[0] = item(first.sectionKey, first.itemKey, .fail)
        XCTAssertFalse(WorkOrderStatusEngine.isAssessmentComplete(device: .scooter, states: states))
    }

    func test_complete_failWithNotePasses() {
        var states = allPass(.mobilityScooter)
        let first = states[0]
        states[0] = item(first.sectionKey, first.itemKey, .fail, note: "needs replacement")
        XCTAssertTrue(WorkOrderStatusEngine.isAssessmentComplete(device: .scooter, states: states))
    }

    // MARK: optional sections (General Mobility has two: mechanical_motor, power_battery)

    func test_complete_optionalSectionNAMarkerSatisfiesWholeSection() {
        // Resolve every NON-optional section's items, then mark each optional
        // section Not Applicable via a section marker row — should be complete
        // without resolving the items inside the optional sections.
        let template = ChecklistTemplate.generalMobility
        var states: [ChecklistItemSnapshot] = []
        for section in template.sections {
            if section.isOptional {
                states.append(item(section.key, "", .notApplicable)) // section marker
            } else {
                states.append(contentsOf: section.items.map { item(section.key, $0.key, .pass) })
            }
        }
        XCTAssertTrue(WorkOrderStatusEngine.isAssessmentComplete(device: .rollator, states: states))
    }

    func test_complete_optionalSectionWithoutMarkerStillRequiresItems() {
        // No marker on the optional sections and their items left unset → incomplete.
        let template = ChecklistTemplate.generalMobility
        var states: [ChecklistItemSnapshot] = []
        for section in template.sections where !section.isOptional {
            states.append(contentsOf: section.items.map { item(section.key, $0.key, .pass) })
        }
        XCTAssertFalse(WorkOrderStatusEngine.isAssessmentComplete(device: .rollator, states: states))
    }

    func test_complete_optionalSectionItemsResolvedWithoutMarkerPasses() {
        // Optional section is Applicable (no NA marker) but every item resolved.
        let states = allPass(.generalMobility)
        XCTAssertTrue(WorkOrderStatusEngine.isAssessmentComplete(device: .rollator, states: states))
    }

    // MARK: device → template routing

    func test_complete_powerChairUsesPowerWheelchairTemplate() {
        // States built for the scooter template must NOT satisfy a power chair.
        let scooterStates = allPass(.mobilityScooter)
        XCTAssertFalse(WorkOrderStatusEngine.isAssessmentComplete(device: .powerChair, states: scooterStates))
        XCTAssertTrue(WorkOrderStatusEngine.isAssessmentComplete(
            device: .powerChair, states: allPass(.powerWheelchair)))
    }

    func test_complete_nilDeviceFallsBackToGeneralMobility() {
        XCTAssertTrue(WorkOrderStatusEngine.isAssessmentComplete(
            device: nil, states: allPass(.generalMobility)))
    }
}
