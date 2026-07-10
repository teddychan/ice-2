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

// MARK: - Section snapshot capture

struct MenuBarLayoutSectionSnapshotTests {
    private func tag(_ title: String) -> MenuBarItemTag {
        MenuBarItemTag(namespace: .string("com.example"), title: title)
    }

    private func spacerTag(_ suffix: String) -> MenuBarItemTag {
        MenuBarItemTag(namespace: .ice, title: MenuBarSpacer.autosaveNamePrefix + suffix)
    }

    @Test func snapshotsCoverEverySectionInCanonicalOrder() {
        let snapshots = MenuBarLayoutProfile.makeSectionSnapshots(from: [:])
        #expect(snapshots.map(\.section) == MenuBarSection.Name.allCases)
        #expect(snapshots.allSatisfy { $0.itemTags.isEmpty })
    }

    @Test func snapshotsPreserveTagOrderWithinSection() {
        let snapshots = MenuBarLayoutProfile.makeSectionSnapshots(from: [
            .visible: [tag("A"), tag("B"), tag("C")],
        ])
        let visible = snapshots.first { $0.section == .visible }
        #expect(visible?.itemTags == [tag("A"), tag("B"), tag("C")])
    }

    @Test func snapshotsExcludeSpacerItems() {
        let snapshots = MenuBarLayoutProfile.makeSectionSnapshots(from: [
            .visible: [tag("A"), spacerTag("1"), tag("B")],
            .hidden: [spacerTag("2")],
        ])
        let visible = snapshots.first { $0.section == .visible }
        let hidden = snapshots.first { $0.section == .hidden }
        #expect(visible?.itemTags == [tag("A"), tag("B")])
        #expect(hidden?.itemTags == [])
    }
}

// MARK: - Create / update capture behavior

@MainActor
struct MenuBarLayoutProfileCaptureTests {
    private func tag(_ title: String) -> MenuBarItemTag {
        MenuBarItemTag(namespace: .string("com.example"), title: title)
    }

    @Test func createProfileCapturesCurrentLayout() async {
        let settings = MenuBarLayoutProfilesSettings()
        settings.captureCurrentLayout = {
            [.visible: [self.tag("A"), self.tag("B")], .hidden: [self.tag("C")]]
        }

        await settings.createProfile(named: "Work")

        #expect(settings.profiles.count == 1)
        let profile = settings.profiles[0]
        #expect(profile.name == "Work")
        #expect(profile.itemCount(for: .visible) == 2)
        #expect(profile.itemCount(for: .hidden) == 1)
        #expect(profile.itemCount(for: .alwaysHidden) == 0)
    }

    /// The core regression test for the bug: after rearranging items, clicking
    /// "Update" must re-capture the *current* layout, not keep the layout that
    /// was stored when the profile was first saved.
    @Test func updateProfileRecapturesCurrentLayout() async {
        let settings = MenuBarLayoutProfilesSettings()

        // Saved when the layout had a single visible item.
        settings.captureCurrentLayout = { [.visible: [self.tag("A")]] }
        await settings.createProfile(named: "Work")
        let original = settings.profiles[0]
        #expect(original.itemCount(for: .visible) == 1)
        #expect(original.itemCount(for: .alwaysHidden) == 0)

        // User rearranges: one item moves to the always-hidden section.
        settings.captureCurrentLayout = {
            [.visible: [self.tag("A")], .alwaysHidden: [self.tag("B")]]
        }
        await settings.updateProfile(original)

        #expect(settings.profiles.count == 1)
        let updated = settings.profiles[0]
        #expect(updated.id == original.id)
        #expect(updated.name == original.name)
        #expect(updated.createdAt == original.createdAt)
        #expect(updated.itemCount(for: .visible) == 1)
        #expect(updated.itemCount(for: .alwaysHidden) == 1)
        #expect(updated.itemTags(for: .alwaysHidden) == [tag("B")])
    }

    @Test func updateProfileLeavesOtherProfilesUntouched() async {
        let settings = MenuBarLayoutProfilesSettings()
        settings.captureCurrentLayout = { [.visible: [self.tag("A")]] }
        await settings.createProfile(named: "First")
        settings.captureCurrentLayout = { [.visible: [self.tag("B")]] }
        await settings.createProfile(named: "Second")

        let second = settings.profiles[1]
        settings.captureCurrentLayout = { [.visible: [self.tag("B"), self.tag("C")]] }
        await settings.updateProfile(second)

        #expect(settings.profiles[0].itemTags(for: .visible) == [tag("A")])
        #expect(settings.profiles[1].itemTags(for: .visible) == [tag("B"), tag("C")])
    }

    @Test func updateUnknownProfileIsNoOp() async {
        let settings = MenuBarLayoutProfilesSettings()
        settings.captureCurrentLayout = { [.visible: [self.tag("A")]] }
        await settings.createProfile(named: "Work")

        let stranger = MenuBarLayoutProfile(
            id: UUID(), name: "Ghost",
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            sections: []
        )
        settings.captureCurrentLayout = { [.visible: [self.tag("Z")]] }
        await settings.updateProfile(stranger)

        #expect(settings.profiles.count == 1)
        #expect(settings.profiles[0].itemTags(for: .visible) == [tag("A")])
    }

    /// If the capture comes back with no items at all (refresh failed, revoked
    /// permission, or a cleared cache), Update must not clobber the saved
    /// profile with an empty layout.
    @Test func updateProfileIgnoresEmptyDictCapture() async {
        let settings = MenuBarLayoutProfilesSettings()
        settings.captureCurrentLayout = { [.visible: [self.tag("A"), self.tag("B")]] }
        await settings.createProfile(named: "Work")
        let original = settings.profiles[0]

        settings.captureCurrentLayout = { [:] }
        await settings.updateProfile(original)

        #expect(settings.profiles.count == 1)
        #expect(settings.profiles[0].itemTags(for: .visible) == [tag("A"), tag("B")])
    }

    @Test func updateProfileIgnoresAllSectionsEmptyCapture() async {
        let settings = MenuBarLayoutProfilesSettings()
        settings.captureCurrentLayout = { [.visible: [self.tag("A")]] }
        await settings.createProfile(named: "Work")
        let original = settings.profiles[0]

        settings.captureCurrentLayout = { [.visible: [], .hidden: [], .alwaysHidden: []] }
        await settings.updateProfile(original)

        #expect(settings.profiles[0].itemTags(for: .visible) == [tag("A")])
    }

    @Test func updateProfileAdvancesUpdatedAtButKeepsCreatedAt() async {
        let settings = MenuBarLayoutProfilesSettings()
        settings.captureCurrentLayout = { [.visible: [self.tag("A")]] }
        await settings.createProfile(named: "Work")
        let original = settings.profiles[0]

        settings.captureCurrentLayout = { [.visible: [self.tag("A"), self.tag("B")]] }
        await settings.updateProfile(original)
        let updated = settings.profiles[0]

        #expect(updated.createdAt == original.createdAt)
        #expect(updated.updatedAt >= original.updatedAt)
    }

    @Test func blankNameGetsUniqueDefault() async {
        let settings = MenuBarLayoutProfilesSettings()
        settings.captureCurrentLayout = { [.visible: [self.tag("A")]] }
        await settings.createProfile(named: "   ")
        await settings.createProfile(named: "")
        #expect(settings.profiles[0].name == "Layout Profile 1")
        #expect(settings.profiles[1].name == "Layout Profile 2")
    }

    @Test func blankNameFillsSmallestFreeIndexAfterDelete() async {
        let settings = MenuBarLayoutProfilesSettings()
        settings.captureCurrentLayout = { [.visible: [self.tag("A")]] }
        await settings.createProfile(named: "")   // "Layout Profile 1"
        await settings.createProfile(named: "")   // "Layout Profile 2"
        settings.deleteProfile(settings.profiles[0]) // frees "Layout Profile 1"
        await settings.createProfile(named: "")
        #expect(settings.profiles.contains { $0.name == "Layout Profile 1" })
    }

    @Test func nonEmptyNameIsTrimmed() async {
        let settings = MenuBarLayoutProfilesSettings()
        settings.captureCurrentLayout = { [.visible: [self.tag("A")]] }
        await settings.createProfile(named: "  Work  ")
        #expect(settings.profiles[0].name == "Work")
    }

    @Test func deleteRemovesOnlyTheTargetProfile() async {
        let settings = MenuBarLayoutProfilesSettings()
        settings.captureCurrentLayout = { [.visible: [self.tag("A")]] }
        await settings.createProfile(named: "First")
        await settings.createProfile(named: "Second")
        let first = settings.profiles[0]
        settings.deleteProfile(first)
        #expect(settings.profiles.count == 1)
        #expect(settings.profiles[0].name == "Second")
        settings.deleteProfile(first) // already gone → no-op
        #expect(settings.profiles.count == 1)
    }
}

// MARK: - Layout-capture cache refresh delay

struct MenuBarLayoutCaptureRefreshDelayTests {
    @Test func noMoveMeansNoDelay() {
        #expect(MenuBarItemManager.layoutCaptureRefreshDelay(sinceLastMove: nil) == .zero)
    }

    @Test func recentMoveWaitsOutTheSkipWindow() {
        // Window is 1s + 50ms; a move 200ms ago must wait the remaining 850ms.
        let delay = MenuBarItemManager.layoutCaptureRefreshDelay(sinceLastMove: .milliseconds(200))
        #expect(delay == .milliseconds(850))
    }

    @Test func oldMoveMeansNoDelay() {
        let delay = MenuBarItemManager.layoutCaptureRefreshDelay(sinceLastMove: .seconds(2))
        #expect(delay == .zero)
    }

    @Test func moveAtExactWindowMeansNoDelay() {
        // The skip window is exactly 1s + 50ms; a move at the boundary needs no wait.
        #expect(MenuBarItemManager.layoutCaptureRefreshDelay(sinceLastMove: .milliseconds(1050)) == .zero)
    }

    @Test func moveJustInsideWindowWaitsRemainder() {
        #expect(MenuBarItemManager.layoutCaptureRefreshDelay(sinceLastMove: .milliseconds(1000)) == .milliseconds(50))
    }
}
