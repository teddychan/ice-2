//
//  HotkeyTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

@MainActor
struct HotkeyTests {
    private var combo: KeyCombination {
        KeyCombination(key: .a, modifiers: [.command, .shift])
    }

    @Test func initStoresActionAndCombination() {
        let hotkey = Hotkey(action: .toggleHiddenSection, keyCombination: combo)
        #expect(hotkey.action == .toggleHiddenSection)
        #expect(hotkey.keyCombination == combo)
    }

    @Test func isDisabledWithoutSetup() {
        // Without an AppState, the listener can't register, so the hotkey
        // stays disabled even once a key combination is assigned.
        let hotkey = Hotkey(action: .toggleHiddenSection, keyCombination: nil)
        #expect(!hotkey.isEnabled)
        hotkey.keyCombination = combo   // triggers enable() → Listener init? → nil
        #expect(!hotkey.isEnabled)
        hotkey.disable()
        #expect(!hotkey.isEnabled)
    }

    @Test func equalityConsidersActionAndCombination() {
        let a = Hotkey(action: .toggleHiddenSection, keyCombination: combo)
        let b = Hotkey(action: .toggleHiddenSection, keyCombination: combo)
        let differentAction = Hotkey(action: .toggleAlwaysHiddenSection, keyCombination: combo)
        let differentCombo = Hotkey(action: .toggleHiddenSection, keyCombination: nil)
        #expect(a == b)
        #expect(a != differentAction)
        #expect(a != differentCombo)
    }

    @Test func hashMatchesForEqualHotkeys() {
        let a = Hotkey(action: .searchMenuBarItems, keyCombination: combo)
        let b = Hotkey(action: .searchMenuBarItems, keyCombination: combo)
        #expect(a.hashValue == b.hashValue)
    }
}
