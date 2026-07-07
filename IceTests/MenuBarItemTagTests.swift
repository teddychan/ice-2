//
//  MenuBarItemTagTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

struct MenuBarItemTagTests {
    private func ordinary() -> MenuBarItemTag {
        MenuBarItemTag(namespace: .string("com.example.Widget"), title: "Widget")
    }

    @Test func ordinaryItemIsMovableHideableNonControlNonSpacer() {
        let tag = ordinary()
        #expect(tag.isMovable)
        #expect(tag.canBeHidden)
        #expect(!tag.isControlItem)
        #expect(!tag.isSpacerItem)
        #expect(!tag.isBentoBox)
        #expect(!tag.isSystemClone)
    }

    @Test func clockAndControlCenterAreImmovable() {
        #expect(!MenuBarItemTag.clock.isMovable)
        #expect(!MenuBarItemTag.controlCenter.isMovable)
    }

    @Test func nonHideableSystemItems() {
        #expect(!MenuBarItemTag.faceTime.canBeHidden)
        #expect(!MenuBarItemTag.audioVideoModule.canBeHidden)
        #expect(!MenuBarItemTag.screenCaptureUI.canBeHidden)
    }

    @Test func controlItemsAreRecognized() {
        #expect(MenuBarItemTag.visibleControlItem.isControlItem)
        #expect(MenuBarItemTag.hiddenControlItem.isControlItem)
        #expect(MenuBarItemTag.alwaysHiddenControlItem.isControlItem)
    }

    @Test func spacerItemIsRecognized() {
        // .ice namespace resolves to the host bundle id under the Ice test host;
        // prefix comes from MenuBarSpacer.
        let spacer = MenuBarItemTag(namespace: .ice, title: "Ice.Spacer.ABCDEF")
        #expect(spacer.isSpacerItem)
        #expect(!ordinary().isSpacerItem)
    }

    @Test func bentoBoxIsRecognized() {
        // MenuBarItemTag.controlCenter has title "BentoBox-0".
        #expect(MenuBarItemTag.controlCenter.isBentoBox)
    }

    @Test func systemCloneIsRecognized() {
        let clone = MenuBarItemTag(namespace: .uuid(UUID()), title: "System Status Item Clone")
        #expect(clone.isSystemClone)
    }

    @Test func namespaceOptionalMapsNilToNull() {
        #expect(MenuBarItemTag.Namespace.optional("x").isString)
        #expect(MenuBarItemTag.Namespace.optional(nil).isNull)
        #expect(!MenuBarItemTag.Namespace.optional("x").isNull)
    }

    @Test func codableRoundTripAcrossNamespaceKinds() throws {
        let tags = [
            ordinary(),
            MenuBarItemTag(namespace: .null, title: ""),
            MenuBarItemTag(namespace: .uuid(UUID()), title: "UUIDItem"),
        ]
        let data = try JSONEncoder().encode(tags)
        let decoded = try JSONDecoder().decode([MenuBarItemTag].self, from: data)
        #expect(decoded == tags)
    }

    @Test func descriptionFormatting() {
        #expect(ordinary().description == "com.example.Widget:Widget")
        #expect(MenuBarItemTag(namespace: .string("ns"), title: "").description == "ns")
    }
}
