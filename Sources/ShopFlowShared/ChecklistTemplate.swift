import Foundation

/// Static definition of one of the three shop checklists. Pure value type —
/// the per-WO state lives in a `ChecklistItemState` row (iOS SwiftData model /
/// server Fluent model) that references these by stable `key` strings, so a
/// label edit here doesn't strand existing data.
///
/// Ported verbatim from the iOS `Sources/Models/ChecklistTemplate.swift`. The
/// keys are load-bearing — they must match the iOS copy exactly so per-WO state
/// round-trips between client and server. When iOS adopts this package (M6) its
/// local copy is deleted in favor of this one.
public struct ChecklistTemplate: Sendable {
    public let id: String
    public let title: String
    public let sections: [ChecklistSection]

    public init(id: String, title: String, sections: [ChecklistSection]) {
        self.id = id
        self.title = title
        self.sections = sections
    }

    public var allItems: [ChecklistItemDef] {
        sections.flatMap(\.items)
    }

    public func section(forKey key: String) -> ChecklistSection? {
        sections.first { $0.key == key }
    }

    /// Pick the right template for a WorkOrder's device type. The two powered-
    /// chair variants share the Power Wheelchair list; everything else (and
    /// any legacy WO with no device type yet) falls back to General Mobility.
    public static func forDevice(_ type: DeviceType?) -> ChecklistTemplate {
        switch type {
        case .scooter:                                  return .mobilityScooter
        case .powerChair, .complexPowerChair:           return .powerWheelchair
        case .rollator, .walker, .cane,
             .liftChair, .bed, .other, .none:           return .generalMobility
        }
    }
}

public struct ChecklistSection: Identifiable, Sendable {
    /// Stable kebab-ish identifier. Persisted on `ChecklistItemState.sectionKey`
    /// — never rename without a migration.
    public let key: String
    public let title: String
    /// True for sections flagged "(if applicable)" in the source markdown.
    /// Renders a section-level Applicable / Not Applicable toggle and lets
    /// the section be satisfied as a whole without resolving each item.
    public let isOptional: Bool
    public let items: [ChecklistItemDef]

    public init(key: String, title: String, isOptional: Bool, items: [ChecklistItemDef]) {
        self.key = key
        self.title = title
        self.isOptional = isOptional
        self.items = items
    }

    public var id: String { key }
}

public struct ChecklistItemDef: Identifiable, Sendable {
    /// Stable kebab-ish identifier scoped within the section. Persisted on
    /// `ChecklistItemState.itemKey`.
    public let key: String
    public let label: String

    public init(key: String, label: String) {
        self.key = key
        self.label = label
    }

    public var id: String { key }
}

/// One assessment-checklist row's state as far as the completeness rule cares —
/// decoupled from any storage model (SwiftData `@Model` / Fluent `Model`) so the
/// rule stays pure and shared by client + server.
///
/// Convention (matches the storage models): a row with `itemKey == ""` is a
/// **section-level applicability marker** for an optional section —
/// `result == .notApplicable` means the section was toggled Not Applicable.
public struct ChecklistItemSnapshot: Sendable, Equatable {
    public let sectionKey: String
    public let itemKey: String
    public let result: ChecklistResult
    public let failureNote: String?

    public init(sectionKey: String, itemKey: String, result: ChecklistResult, failureNote: String? = nil) {
        self.sectionKey = sectionKey
        self.itemKey = itemKey
        self.result = result
        self.failureNote = failureNote
    }

    public var isSectionMarker: Bool { itemKey.isEmpty }

    /// True when this row counts as a resolved answer for completion gating.
    /// A `.fail` without a non-empty note is intentionally treated as unresolved
    /// so the WO can't slip into Ready for Pickup with a phantom failure.
    public var isResolved: Bool {
        switch result {
        case .pass, .notApplicable: return true
        case .fail:
            return !(failureNote ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .unset:
            return false
        }
    }
}

// MARK: - Transcribed checklists
//
// Transcribed verbatim from the three .md files at the iOS repo root. Keys are
// kebab-ish snake_case and intentionally decoupled from the human-readable
// labels so a copy edit doesn't strand existing per-WO state.

extension ChecklistTemplate {
    public static let mobilityScooter = ChecklistTemplate(
        id: "mobility_scooter",
        title: "Mobility Scooter 8-Point Assessment",
        sections: [
            ChecklistSection(
                key: "battery_health",
                title: "Battery Health Check",
                isOptional: false,
                items: [
                    .init(key: "terminals",        label: "Inspect terminals for corrosion and secure connections"),
                    .init(key: "voltage_charge",   label: "Test voltage and charge level"),
                    .init(key: "charger_working",  label: "Confirm charger is working properly"),
                ]
            ),
            ChecklistSection(
                key: "brake_system",
                title: "Brake System Check",
                isOptional: false,
                items: [
                    .init(key: "em_mechanical",    label: "Test electromagnetic and mechanical brakes"),
                    .init(key: "freewheel_lever",  label: "Confirm proper function of freewheel lever"),
                ]
            ),
            ChecklistSection(
                key: "controls_electronics",
                title: "Controls & Electronics",
                isOptional: false,
                items: [
                    .init(key: "key_power",        label: "Check key switch or power button"),
                    .init(key: "throttle_panel",   label: "Test throttle, horn, lights, and display panel"),
                ]
            ),
            ChecklistSection(
                key: "motor_drive",
                title: "Motor & Drive Test",
                isOptional: false,
                items: [
                    .init(key: "forward_reverse", label: "Run scooter forward and reverse"),
                    .init(key: "unusual_noises",  label: "Listen for unusual noises"),
                    .init(key: "smooth_accel",    label: "Check for smooth acceleration and braking"),
                ]
            ),
            ChecklistSection(
                key: "safety_accessories",
                title: "Safety Features & Accessories",
                isOptional: false,
                items: [
                    .init(key: "accessories_secure", label: "Verify all accessories are secure and functional"),
                    .init(key: "lights_mirrors",     label: "Inspect lights, reflectors, and mirrors"),
                ]
            ),
            ChecklistSection(
                key: "seat_frame",
                title: "Seat & Frame Stability",
                isOptional: false,
                items: [
                    .init(key: "stability_comfort", label: "Check for stability and comfort"),
                    .init(key: "seat_tiller",       label: "Verify seat, armrests, and tiller are secure and adjustable"),
                ]
            ),
            ChecklistSection(
                key: "tires_wheels",
                title: "Tires & Wheels",
                isOptional: false,
                items: [
                    .init(key: "spin_secure",  label: "Ensure wheels spin freely and securely"),
                    .init(key: "wear_damage",  label: "Inspect for wear, damage, and proper inflation"),
                ]
            ),
            ChecklistSection(
                key: "visual_inspection",
                title: "Visual Inspection",
                isOptional: false,
                items: [
                    .init(key: "loose_corrosion", label: "Inspect for loose screws, corrosion, or worn parts"),
                    .init(key: "frame_cracks",    label: "Check frame for cracks or damage"),
                ]
            ),
        ]
    )

    public static let powerWheelchair = ChecklistTemplate(
        id: "power_wheelchair",
        title: "Power Wheelchair 8-Point Assessment",
        sections: [
            ChecklistSection(
                key: "battery_charging",
                title: "Battery & Charging System",
                isOptional: false,
                items: [
                    .init(key: "terminals",       label: "Inspect terminals for corrosion and secure connections"),
                    .init(key: "charger_port",    label: "Confirm charger functionality and port integrity"),
                    .init(key: "voltage_charge",  label: "Test battery voltage and charge retention"),
                ]
            ),
            ChecklistSection(
                key: "brake_freewheel",
                title: "Brake & Freewheel Function",
                isOptional: false,
                items: [
                    .init(key: "stops_safely",   label: "Confirm chair stops safely and evenly"),
                    .init(key: "freewheel_lvr",  label: "Ensure freewheel levers function correctly and are clearly labeled"),
                    .init(key: "motor_brakes",   label: "Test automatic motor brakes for hold and release"),
                ]
            ),
            ChecklistSection(
                key: "joystick_electronics",
                title: "Joystick & Electronics",
                isOptional: false,
                // NOTE: power-wheelchair-checklist.md:16 has the same
                // "joystick responsiveness" item twice — flagged in the
                // source .md as likely a missing distinct check (e.g.
                // centering / boot inspection). Transcribed once here;
                // re-add the second item if the original is recovered.
                items: [
                    .init(key: "controller_errors", label: "Check controller and display for error codes"),
                    .init(key: "joystick_response", label: "Test joystick responsiveness and accuracy"),
                ]
            ),
            ChecklistSection(
                key: "motor_drive",
                title: "Motor & Drive Function",
                isOptional: false,
                items: [
                    .init(key: "directional",   label: "Test all directional movements (forward, reverse, turning)"),
                    .init(key: "motor_sounds",  label: "Listen for abnormal sounds from motors or gearboxes"),
                    .init(key: "smooth_accel",  label: "Ensure smooth acceleration and braking"),
                ]
            ),
            ChecklistSection(
                key: "safety_accessories",
                title: "Safety Features & Accessories",
                isOptional: false,
                items: [
                    .init(key: "additional_controls", label: "Test any additional controls (tilt, lift, attendant drive)"),
                    .init(key: "lights_antitip",      label: "Inspect lights, reflectors, seatbelt, and anti-tip wheels"),
                    .init(key: "accessory_install",   label: "Verify secure installation of accessories (oxygen holder, tray, etc.)"),
                ]
            ),
            ChecklistSection(
                key: "seating_adjust",
                title: "Seating System & Adjustability",
                isOptional: false,
                items: [
                    .init(key: "upholstery",        label: "Inspect upholstery for tears or breakdown"),
                    .init(key: "seat_secure",       label: "Ensure seat, armrests, footrests, and backrest are secure and adjustable"),
                    .init(key: "tilt_recline_elev", label: "Check tilt, recline, or elevation functions (if applicable)"),
                ]
            ),
            ChecklistSection(
                key: "tires_casters",
                title: "Tires, Casters & Wheels",
                isOptional: false,
                items: [
                    .init(key: "rotate_aligned",  label: "Ensure all wheels rotate freely and are aligned"),
                    .init(key: "drive_casters",   label: "Inspect drive tires and casters for wear or damage"),
                    .init(key: "pneumatic_infl",  label: "Check for proper inflation (if pneumatic)"),
                ]
            ),
            ChecklistSection(
                key: "visual_inspection",
                title: "Visual Inspection",
                isOptional: false,
                items: [
                    .init(key: "frame_base",   label: "Check frame, base, and shroud for cracks or damage"),
                    .init(key: "hardware",     label: "Look for loose hardware, corrosion, or wear on components"),
                ]
            ),
        ]
    )

    public static let generalMobility = ChecklistTemplate(
        id: "general_mobility",
        title: "General Mobility 8-Point Assessment",
        sections: [
            ChecklistSection(
                key: "brakes_stability",
                title: "Brakes & Stability",
                isOptional: false,
                items: [
                    .init(key: "anti_tip",       label: "Ensure anti-tip wheels (if present) are intact and functional"),
                    .init(key: "stability",      label: "Test stability on flat and slightly uneven surfaces"),
                    .init(key: "brakes_hold",    label: "Verify that brakes engage and hold the equipment securely"),
                ]
            ),
            ChecklistSection(
                key: "controls_electronics",
                title: "Controls & Electronics",
                isOptional: false,
                items: [
                    .init(key: "frayed_wires",   label: "Look for frayed wires or faulty connections"),
                    .init(key: "controls_resp",  label: "Test hand controls, joysticks, remotes, and buttons for responsiveness"),
                    .init(key: "lights_display", label: "Verify all lights, indicators, and digital displays are working"),
                ]
            ),
            ChecklistSection(
                key: "mechanical_motor",
                title: "Mechanical & Motor Function (if applicable)",
                isOptional: true,
                items: [
                    .init(key: "movement_funcs", label: "Operate all movement functions: drive, lift, tilt, recline, etc."),
                    .init(key: "motor_sounds",   label: "Listen for grinding, clicking, or unusual motor sounds"),
                    .init(key: "smooth_perf",    label: "Ensure smooth operation and consistent performance"),
                ]
            ),
            ChecklistSection(
                key: "power_battery",
                title: "Power & Battery (if applicable)",
                isOptional: true,
                items: [
                    .init(key: "terminals_wear", label: "Inspect battery terminals and wiring for corrosion or wear"),
                    .init(key: "voltage_charge", label: "Test battery voltage and charging capability"),
                    .init(key: "charger_supply", label: "Confirm the charger and power supply are functioning properly"),
                ]
            ),
            ChecklistSection(
                key: "safety_accessories",
                title: "Safety Features & Accessories",
                isOptional: false,
                items: [
                    .init(key: "no_obstructions", label: "Ensure no obstructions or hazards in the equipment's configuration"),
                    .init(key: "addons",          label: "Check for proper installation and operation of add-ons (baskets, trays, oxygen holders)"),
                    .init(key: "seatbelts_grab",  label: "Inspect seatbelts, grab bars, lights, reflectors, and safety locks"),
                ]
            ),
            ChecklistSection(
                key: "seating_support",
                title: "Seating, Support & Adjustability",
                isOptional: false,
                items: [
                    .init(key: "seat_armrests",   label: "Ensure seat, backrest, and armrests are secure and properly aligned"),
                    .init(key: "adjustable",      label: "Test any adjustable features (height, angle, footrests) for smooth operation"),
                    .init(key: "upholstery",      label: "Check for tears or sagging in upholstery or cushions"),
                ]
            ),
            ChecklistSection(
                key: "visual_inspection",
                title: "Visual Inspection",
                isOptional: false,
                items: [
                    .init(key: "fasteners",       label: "Inspect fasteners, screws, and hardware for looseness or missing parts"),
                    .init(key: "misuse_damage",   label: "Look for signs of misuse, modifications, or damage"),
                    .init(key: "frame_cracks",    label: "Check for cracks, dents, rust, or visible wear on the frame and body"),
                ]
            ),
            ChecklistSection(
                key: "wheels_tires",
                title: "Wheels, Tires & Casters",
                isOptional: false,
                items: [
                    .init(key: "wear_punctures",  label: "Check for wear, flat spots, or punctures"),
                    .init(key: "caster_axles",    label: "Test caster mobility and inspect axles for damage"),
                    .init(key: "spin_track",      label: "Ensure wheels spin freely and track straight"),
                ]
            ),
        ]
    )
}
