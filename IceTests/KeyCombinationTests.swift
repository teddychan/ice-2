//
//  KeyCombinationTests.swift
//  IceTests
//

import AppKit
import Carbon.HIToolbox
import Foundation
import Testing
@testable import Ice_2

struct KeyCombinationTests {
    @Test func initFromNSEventExtractsKeyAndModifiers() throws {
        let event = try #require(NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [.command, .shift],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "a",
            charactersIgnoringModifiers: "a",
            isARepeat: false,
            keyCode: UInt16(kVK_ANSI_A)
        ))
        let combination = KeyCombination(event: event)
        #expect(combination.key == .a)
        #expect(combination.modifiers == [.command, .shift])
    }

    @Test func isSystemReservedExercisesSymbolicHotkeyLookup() {
        // A combination with every modifier is extremely unlikely to be a
        // registered system hotkey, so this reports false while still
        // exercising the CopySymbolicHotKeys lookup path.
        let combination = KeyCombination(key: .f19, modifiers: [.command, .control, .option, .shift])
        #expect(!combination.isSystemReserved)
    }

    @Test func displayValueJoinsModifiersAndCapitalizedKey() {
        let combination = KeyCombination(key: .space, modifiers: [.command, .shift])
        #expect(combination.displayValue == "⇧⌘ Space")
    }

    @Test func displayValueWithNoModifiers() {
        let combination = KeyCombination(key: .escape, modifiers: [])
        #expect(combination.displayValue == " ⎋")
    }

    @Test func equalityConsidersKeyAndModifiers() {
        let a = KeyCombination(key: .a, modifiers: [.command])
        let b = KeyCombination(key: .a, modifiers: [.command])
        let c = KeyCombination(key: .a, modifiers: [.control])
        let d = KeyCombination(key: .b, modifiers: [.command])
        #expect(a == b)
        #expect(a != c)
        #expect(a != d)
    }

    @Test func codableRoundTrip() throws {
        let combination = KeyCombination(key: .f5, modifiers: [.control, .option])
        let data = try JSONEncoder().encode(combination)
        let decoded = try JSONDecoder().decode(KeyCombination.self, from: data)
        #expect(decoded == combination)
    }

    @Test func encodesAsTwoElementArray() throws {
        let combination = KeyCombination(key: .a, modifiers: .command)
        let data = try JSONEncoder().encode(combination)
        let array = try JSONDecoder().decode([Int].self, from: data)
        #expect(array == [KeyCode.a.rawValue, Modifiers.command.rawValue])
    }

    @Test func decodingWrongElementCountThrows() {
        let data = Data("[1, 2, 3]".utf8)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(KeyCombination.self, from: data)
        }
    }
}
