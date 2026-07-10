//
//  KeyCodeTests.swift
//  IceTests
//

import Carbon.HIToolbox
import Foundation
import Testing
@testable import Ice_2

struct KeyCodeTests {
    @Test func rawRepresentableRoundTrip() {
        let code = KeyCode(rawValue: kVK_ANSI_A)
        #expect(code.rawValue == kVK_ANSI_A)
        #expect(KeyCode.a == code)
    }

    @Test func distinctKeysAreNotEqual() {
        #expect(KeyCode.a != KeyCode.b)
        #expect(KeyCode.space != KeyCode.tab)
    }

    @Test func codableRoundTrip() throws {
        let keys: [KeyCode] = [.a, .space, .f5, .leftArrow, .keypad0]
        let data = try JSONEncoder().encode(keys)
        let decoded = try JSONDecoder().decode([KeyCode].self, from: data)
        #expect(decoded == keys)
    }

    @Test func stringValueUsesCustomSymbolMappings() {
        #expect(KeyCode.space.stringValue == "Space")
        #expect(KeyCode.tab.stringValue == "⇥")
        #expect(KeyCode.return.stringValue == "⏎")
        #expect(KeyCode.delete.stringValue == "⌫")
        #expect(KeyCode.escape.stringValue == "⎋")
        #expect(KeyCode.leftArrow.stringValue == "←")
        #expect(KeyCode.command.stringValue == "⌘")
        #expect(KeyCode.f1.stringValue == "F1")
        #expect(KeyCode.f12.stringValue == "F12")
    }

    @Test func stringValueFallsBackToKeyEquivalentForLetters() {
        // Letters have no custom mapping, so they fall back to the
        // system key-equivalent lookup. On an ANSI layout this is "a".
        #expect(KeyCode.a.stringValue.lowercased() == "a")
    }

    @Test func hashableUsableInSet() {
        let set: Set<KeyCode> = [.a, .a, .b]
        #expect(set.count == 2)
    }
}
