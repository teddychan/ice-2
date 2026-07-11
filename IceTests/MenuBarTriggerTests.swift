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
        action: MenuBarTrigger.Action = .showHiddenSection,
        groupID: UUID? = nil
    ) -> MenuBarTrigger {
        MenuBarTrigger(
            id: UUID(),
            name: "Safari",
            createdAt: Date(timeIntervalSince1970: 0),
            condition: .frontmostApplication(bundleIdentifier: bundle),
            action: action,
            itemGroupID: groupID
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
        #expect(MenuBarTrigger.Action.showHiddenSection.rawValue == "showHiddenSection")
        #expect(MenuBarTrigger.Action.temporarilyShowItemGroup.rawValue == "temporarilyShowItemGroup")
    }

    @Test func codableRoundTrip() throws {
        let original = trigger(action: .temporarilyShowItemGroup, groupID: UUID())
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MenuBarTrigger.self, from: data)
        #expect(decoded == original)
    }

    @Test func triggerTargetEquality() {
        let id = UUID()
        #expect(MenuBarTriggerTarget.hiddenSection == .hiddenSection)
        #expect(MenuBarTriggerTarget.itemGroup(id) == .itemGroup(id))
        #expect(MenuBarTriggerTarget.itemGroup(id) != .itemGroup(UUID()))
        #expect(MenuBarTriggerTarget.itemGroup(id) != .hiddenSection)
    }
}
