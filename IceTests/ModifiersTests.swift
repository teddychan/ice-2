//
//  ModifiersTests.swift
//  IceTests
//

import AppKit
import Carbon.HIToolbox
import Foundation
import Testing
@testable import Ice_2

struct ModifiersTests {
    private let all: Modifiers = [.control, .option, .shift, .command]

    @Test func rawValuesAreDistinctBits() {
        #expect(Modifiers.control.rawValue == 1 << 0)
        #expect(Modifiers.option.rawValue == 1 << 1)
        #expect(Modifiers.shift.rawValue == 1 << 2)
        #expect(Modifiers.command.rawValue == 1 << 3)
    }

    @Test func canonicalOrderMatchesAppleStyleGuide() {
        #expect(Modifiers.canonicalOrder == [.control, .option, .shift, .command])
    }

    @Test func symbolicValueOrdersControlOptionShiftCommand() {
        #expect(all.symbolicValue == "⌃⌥⇧⌘")
        #expect(Modifiers().symbolicValue == "")
        #expect(Modifiers.command.symbolicValue == "⌘")
        #expect(Modifiers([.shift, .command]).symbolicValue == "⇧⌘")
    }

    @Test func nsEventFlagsRoundTrip() {
        let flags = all.nsEventFlags
        #expect(flags.contains(.control))
        #expect(flags.contains(.option))
        #expect(flags.contains(.shift))
        #expect(flags.contains(.command))
        #expect(Modifiers(nsEventFlags: flags) == all)
    }

    @Test func cgEventFlagsRoundTrip() {
        let flags = all.cgEventFlags
        #expect(flags.contains(.maskControl))
        #expect(flags.contains(.maskAlternate))
        #expect(flags.contains(.maskShift))
        #expect(flags.contains(.maskCommand))
        #expect(Modifiers(cgEventFlags: flags) == all)
    }

    @Test func carbonFlagsRoundTrip() {
        let flags = all.carbonFlags
        #expect(flags & controlKey == controlKey)
        #expect(flags & optionKey == optionKey)
        #expect(flags & shiftKey == shiftKey)
        #expect(flags & cmdKey == cmdKey)
        #expect(Modifiers(carbonFlags: flags) == all)
    }

    @Test func emptyConversionsProduceEmptyModifiers() {
        #expect(Modifiers(nsEventFlags: []) == Modifiers())
        #expect(Modifiers(cgEventFlags: []) == Modifiers())
        #expect(Modifiers(carbonFlags: 0) == Modifiers())
    }

    @Test func partialConversionPreservesOnlySetModifiers() {
        let subset: Modifiers = [.control, .shift]
        #expect(Modifiers(nsEventFlags: subset.nsEventFlags) == subset)
        #expect(Modifiers(cgEventFlags: subset.cgEventFlags) == subset)
        #expect(Modifiers(carbonFlags: subset.carbonFlags) == subset)
    }

    @Test func codableRoundTrip() throws {
        let data = try JSONEncoder().encode(all)
        let decoded = try JSONDecoder().decode(Modifiers.self, from: data)
        #expect(decoded == all)
    }
}
