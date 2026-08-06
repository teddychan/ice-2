//
//  MenuBarTriggerTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

struct MenuBarTriggerTests {
    private func trigger(
        bundle: String = "com.apple.Safari",
        action: MenuBarTrigger.Action = .showHiddenSection
    ) -> MenuBarTrigger {
        MenuBarTrigger(
            id: UUID(),
            name: "Safari",
            createdAt: Date(timeIntervalSince1970: 0),
            condition: .frontmostApplication(bundleIdentifier: bundle),
            action: action
        )
    }

    @Test func bundleIdentifierReadsCondition() {
        #expect(trigger(bundle: "com.apple.Mail").bundleIdentifier == "com.apple.Mail")
    }

    @Test func matchesOnlyTheConfiguredBundle() {
        let t = trigger(bundle: "com.apple.Safari")
        #expect(t.matches(frontmostBundleIdentifier: "com.apple.Safari"))
        #expect(!t.matches(frontmostBundleIdentifier: "com.apple.Mail"))
    }

    @Test func actionRawValues() {
        // The raw value is what lands in the user's preferences, so it is part of the
        // stored format and must not drift with a rename of the case.
        #expect(MenuBarTrigger.Action.showHiddenSection.rawValue == "showHiddenSection")
    }

    @Test func codableRoundTrip() throws {
        let original = trigger()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MenuBarTrigger.self, from: data)
        #expect(decoded == original)
    }
}

/// Pins that removing an action can never cost a user the triggers they still use.
///
/// `Action` is a raw-value enum, so a trigger stored by an older version with an action
/// this version no longer has — `temporarilyShowItemGroup`, removed in 2.12.0 with item
/// groups — throws when decoded. `[MenuBarTrigger]` decoded in one go would throw on the
/// first such element, and the load path only logs the error, so the user would silently
/// lose *every* trigger they had rather than just the obsolete one.
///
/// The JSON here is written by hand on purpose: the type can no longer produce an
/// obsolete trigger, so encoding a fixture would prove nothing about old data.
struct MenuBarTriggerLegacyDecodingTests {
    private func data(_ json: String) -> Data {
        Data(json.utf8)
    }

    private let obsoleteTrigger = """
        {
          "id": "6E7F5E4E-0000-4000-8000-000000000001",
          "name": "Legacy Group Trigger",
          "createdAt": 0,
          "condition": { "frontmostApplication": { "bundleIdentifier": "com.apple.Mail" } },
          "action": "temporarilyShowItemGroup",
          "itemGroupID": "6E7F5E4E-0000-4000-8000-000000000002"
        }
        """

    private let currentTrigger = """
        {
          "id": "6E7F5E4E-0000-4000-8000-000000000003",
          "name": "Safari",
          "createdAt": 0,
          "condition": { "frontmostApplication": { "bundleIdentifier": "com.apple.Safari" } },
          "action": "showHiddenSection"
        }
        """

    @Test func keepsStillValidTriggersAlongsideAnObsoleteOne() throws {
        let decoded = try MenuBarTriggerSettings.decodeTriggers(
            from: data("[\(obsoleteTrigger),\(currentTrigger)]"),
            using: JSONDecoder()
        )
        // The obsolete one is dropped; the Safari trigger survives.
        #expect(decoded.count == 1)
        #expect(decoded.first?.name == "Safari")
        #expect(decoded.first?.action == .showHiddenSection)
    }

    @Test func anObsoleteTriggerAloneDecodesToEmptyRatherThanThrowing() throws {
        let decoded = try MenuBarTriggerSettings.decodeTriggers(
            from: data("[\(obsoleteTrigger)]"),
            using: JSONDecoder()
        )
        #expect(decoded.isEmpty)
    }

    @Test func aLeftoverItemGroupIDIsIgnoredRatherThanRejected() throws {
        // Older versions wrote `itemGroupID` on every trigger, including hidden-section
        // ones. That key is gone from the type; an unknown key must not fail the decode.
        let withStaleKey = """
            {
              "id": "6E7F5E4E-0000-4000-8000-000000000004",
              "name": "Mail",
              "createdAt": 0,
              "condition": { "frontmostApplication": { "bundleIdentifier": "com.apple.Mail" } },
              "action": "showHiddenSection",
              "itemGroupID": "6E7F5E4E-0000-4000-8000-000000000005"
            }
            """
        let decoded = try MenuBarTriggerSettings.decodeTriggers(
            from: data("[\(withStaleKey)]"),
            using: JSONDecoder()
        )
        #expect(decoded.count == 1)
        #expect(decoded.first?.name == "Mail")
    }

    @Test func validTriggersRoundTripThroughTheLenientPath() throws {
        let decoded = try MenuBarTriggerSettings.decodeTriggers(
            from: data("[\(currentTrigger)]"),
            using: JSONDecoder()
        )
        #expect(decoded.count == 1)
    }
}
