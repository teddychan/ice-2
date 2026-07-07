//
//  MenuBarLayoutProfileTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

struct MenuBarLayoutProfileTests {
    private func tag(_ title: String) -> MenuBarItemTag {
        MenuBarItemTag(namespace: .string("com.example"), title: title)
    }

    private func sampleProfile() -> MenuBarLayoutProfile {
        MenuBarLayoutProfile(
            id: UUID(),
            name: "Work",
            createdAt: Date(timeIntervalSince1970: 1000),
            updatedAt: Date(timeIntervalSince1970: 2000),
            sections: [
                .init(section: .visible, itemTags: [tag("A"), tag("B")]),
                .init(section: .hidden, itemTags: [tag("C")]),
                .init(section: .alwaysHidden, itemTags: []),
            ]
        )
    }

    @Test func itemTagsAndCountsPerSection() {
        let profile = sampleProfile()
        #expect(profile.itemTags(for: .visible) == [tag("A"), tag("B")])
        #expect(profile.itemCount(for: .visible) == 2)
        #expect(profile.itemTags(for: .hidden) == [tag("C")])
        #expect(profile.itemCount(for: .alwaysHidden) == 0)
    }

    @Test func missingSectionReturnsEmpty() {
        let profile = MenuBarLayoutProfile(
            id: UUID(), name: "Empty",
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            sections: []
        )
        #expect(profile.itemTags(for: .visible).isEmpty)
        #expect(profile.itemCount(for: .hidden) == 0)
    }

    @Test func profileCodableRoundTrip() throws {
        let profile = sampleProfile()
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(MenuBarLayoutProfile.self, from: data)
        #expect(decoded == profile)
    }

    @Test func groupCountAndCodableRoundTrip() throws {
        let group = MenuBarItemGroup(
            id: UUID(), name: "G",
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 2),
            itemTags: [tag("A"), tag("B")]
        )
        #expect(group.itemCount == 2)
        let data = try JSONEncoder().encode(group)
        let decoded = try JSONDecoder().decode(MenuBarItemGroup.self, from: data)
        #expect(decoded == group)
    }
}
