//
//  HotkeyActionTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

struct HotkeyActionTests {
    @Test func rawValuesMatchPersistedStrings() {
        #expect(HotkeyAction.toggleHiddenSection.rawValue == "ToggleHiddenSection")
        #expect(HotkeyAction.toggleAlwaysHiddenSection.rawValue == "ToggleAlwaysHiddenSection")
        #expect(HotkeyAction.toggleSectionDividerIcons.rawValue == "ToggleSectionDividerIcons")
        #expect(HotkeyAction.searchMenuBarItems.rawValue == "SearchMenuBarItems")
        #expect(HotkeyAction.temporarilyShowMenuBarItem.rawValue == "TemporarilyShowMenuBarItem")
        #expect(HotkeyAction.enableIceBar.rawValue == "EnableIceBar")
        #expect(HotkeyAction.toggleAutoRehide.rawValue == "ToggleAutoRehide")
        #expect(HotkeyAction.toggleApplicationMenus.rawValue == "ToggleApplicationMenus")
    }

    @Test func allCasesAreEnumerated() {
        #expect(HotkeyAction.allCases.count == 8)
    }

    @Test func initFromRawValue() {
        #expect(HotkeyAction(rawValue: "EnableIceBar") == .enableIceBar)
        #expect(HotkeyAction(rawValue: "NotARealAction") == nil)
    }

    @Test func codableRoundTripForAllCases() throws {
        for action in HotkeyAction.allCases {
            let data = try JSONEncoder().encode(action)
            let decoded = try JSONDecoder().decode(HotkeyAction.self, from: data)
            #expect(decoded == action)
        }
    }

    @Test func decodesFromRawStringLiteral() throws {
        let data = Data("\"ToggleAutoRehide\"".utf8)
        let decoded = try JSONDecoder().decode(HotkeyAction.self, from: data)
        #expect(decoded == .toggleAutoRehide)
    }
}
