//
//  NewMenuBarItemPlacementTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

struct NewMenuBarItemPlacementTests {
    // MARK: Helpers

    private func tag(_ title: String, namespace: String = "com.example.app") -> MenuBarItemTag {
        MenuBarItemTag(namespace: .string(namespace), title: title)
    }

    // MARK: isPlaceable

    @Test func placeableAcceptsOrdinaryItem() {
        #expect(NewMenuBarItemPlacement.isPlaceable(tag("Widget")))
    }

    @Test func placeableRejectsControlItems() {
        for controlItem in MenuBarItemTag.controlItems {
            #expect(!NewMenuBarItemPlacement.isPlaceable(controlItem))
        }
    }

    @Test func placeableRejectsImmovableItems() {
        // Pinned to the trailing end of the menu bar by macOS.
        #expect(!NewMenuBarItemPlacement.isPlaceable(.clock))
        #expect(!NewMenuBarItemPlacement.isPlaceable(.controlCenter))
    }

    @Test func placeableRejectsNonHideableItems() {
        #expect(!NewMenuBarItemPlacement.isPlaceable(.audioVideoModule))
        #expect(!NewMenuBarItemPlacement.isPlaceable(.faceTime))
    }

    @Test func placeableRejectsSpacers() {
        let spacer = MenuBarItemTag(
            namespace: .ice,
            title: MenuBarSpacer.autosaveNamePrefix + "1"
        )
        #expect(!NewMenuBarItemPlacement.isPlaceable(spacer))
    }

    // A UUID namespace is minted per process launch, so the same item can carry
    // a different tag after a relaunch. Placing on that identity would move the
    // item every single launch.
    @Test func placeableRejectsUnstableUUIDNamespace() {
        let unstable = MenuBarItemTag(namespace: .uuid(UUID()), title: "Widget")
        #expect(!NewMenuBarItemPlacement.isPlaceable(unstable))
    }

    @Test func placeableRejectsSystemClone() {
        let clone = MenuBarItemTag(
            namespace: .uuid(UUID()),
            title: "System Status Item Clone"
        )
        #expect(clone.isSystemClone)
        #expect(!NewMenuBarItemPlacement.isPlaceable(clone))
    }

    // An untitled item can't be told apart from its siblings in the same namespace.
    @Test func placeableRejectsEmptyTitle() {
        #expect(!NewMenuBarItemPlacement.isPlaceable(tag("")))
    }

    // MARK: candidateTags

    @Test func candidatesAreTheUnknownLeadingRun() {
        let ordered = [
            tag("New A"),
            tag("New B"),
            MenuBarItemTag.alwaysHiddenControlItem,
            tag("Parked"),
            MenuBarItemTag.hiddenControlItem,
            tag("Visible"),
        ]
        let candidates = NewMenuBarItemPlacement.candidateTags(in: ordered, known: [])
        #expect(candidates == [tag("New A"), tag("New B")])
    }

    // Everything beyond a known item is sitting where the user left it, not in
    // the slot macOS hands to brand-new items.
    @Test func walkStopsAtFirstKnownTag() {
        let ordered = [
            tag("New"),
            tag("Known"),
            tag("Behind The Known One"),
            MenuBarItemTag.alwaysHiddenControlItem,
        ]
        let candidates = NewMenuBarItemPlacement.candidateTags(
            in: ordered,
            known: [tag("Known")]
        )
        #expect(candidates == [tag("New")])
    }

    @Test func nonPlaceableTagsDoNotEndTheWalk() {
        let ordered = [
            tag("New A"),
            MenuBarItemTag.clock, // Not placeable; must be skipped, not stop the walk.
            tag("New B"),
            MenuBarItemTag.alwaysHiddenControlItem,
        ]
        let candidates = NewMenuBarItemPlacement.candidateTags(in: ordered, known: [])
        #expect(candidates == [tag("New A"), tag("New B")])
    }

    @Test func candidatesAreDeduplicatedAndKeepOrder() {
        let ordered = [
            tag("B"),
            tag("A"),
            tag("B"),
            MenuBarItemTag.hiddenControlItem,
        ]
        let candidates = NewMenuBarItemPlacement.candidateTags(in: ordered, known: [])
        #expect(candidates == [tag("B"), tag("A")])
    }

    @Test func noCandidatesWhenEverythingIsKnown() {
        let ordered = [tag("A"), tag("B"), MenuBarItemTag.hiddenControlItem]
        let candidates = NewMenuBarItemPlacement.candidateTags(
            in: ordered,
            known: [tag("A"), tag("B")]
        )
        #expect(candidates.isEmpty)
    }

    // No control item means the read failed. Treating the whole menu bar as a
    // landing zone would move everything into the visible section.
    @Test func noCandidatesWithoutAControlItem() {
        let ordered = [tag("A"), tag("B")]
        #expect(NewMenuBarItemPlacement.candidateTags(in: ordered, known: []).isEmpty)
    }

    @Test func noCandidatesWhenControlItemIsLeftmost() {
        let ordered = [MenuBarItemTag.hiddenControlItem, tag("Visible")]
        #expect(NewMenuBarItemPlacement.candidateTags(in: ordered, known: []).isEmpty)
    }

    // MARK: tagsToRecord

    @Test func recordsPlacedCandidatesButNotFailedOnes() {
        let ordered = [tag("Placed"), tag("Failed"), MenuBarItemTag.hiddenControlItem]
        let recorded = NewMenuBarItemPlacement.tagsToRecord(
            seen: ordered,
            candidates: [tag("Placed"), tag("Failed")],
            placed: [tag("Placed")]
        )
        #expect(recorded.contains(tag("Placed")))
        // Still in the landing zone, so the next pass finds and retries it.
        #expect(!recorded.contains(tag("Failed")))
    }

    // The case that matters: an unknown item behind the tag that stopped the
    // walk is neither placed nor a candidate. If it were left unrecorded, the
    // day the blocking item's app quit the walk would run further and drag it
    // out of the always-hidden section.
    @Test func recordsUnknownTagsBehindTheStoppingPoint() {
        let ordered = [
            tag("Known"),
            tag("Parked But Unrecorded"),
            MenuBarItemTag.alwaysHiddenControlItem,
        ]
        let recorded = NewMenuBarItemPlacement.tagsToRecord(
            seen: ordered,
            candidates: [],
            placed: []
        )
        #expect(recorded.contains(tag("Parked But Unrecorded")))
    }

    @Test func recordsNeverIncludeNonPlaceableTags() {
        let ordered = [
            tag("Widget"),
            MenuBarItemTag.clock,
            MenuBarItemTag.hiddenControlItem,
        ]
        let recorded = NewMenuBarItemPlacement.tagsToRecord(
            seen: ordered,
            candidates: [],
            placed: []
        )
        #expect(recorded == [tag("Widget")])
    }

    // MARK: Persistence

    @Test func knownTagsRoundTrip() throws {
        let tags: Set<MenuBarItemTag> = [tag("A"), tag("B"), .timeMachine]
        let data = try #require(NewMenuBarItemPlacement.encode(tags))
        #expect(NewMenuBarItemPlacement.decodeKnownTags(from: data) == tags)
    }

    @Test func emptySetRoundTripsAndIsNotNil() throws {
        let data = try #require(NewMenuBarItemPlacement.encode([]))
        // Distinguishable from an unreadable payload: an empty set is a real
        // answer, whereas nil sends the manager down the first-run path.
        #expect(NewMenuBarItemPlacement.decodeKnownTags(from: data) == [])
    }

    @Test func undecodablePayloadYieldsNil() {
        let garbage = Data("not json".utf8)
        #expect(NewMenuBarItemPlacement.decodeKnownTags(from: garbage) == nil)
    }
}
