//
//  ControlItemLengthTests.swift
//  IceTests
//

import Cocoa
import Testing
@testable import Ice_2

struct ControlItemLengthTests {
    private let dividers: [ControlItem.Identifier] = [.hidden, .alwaysHidden]

    // The legacy backend hides items by expanding the divider so they overflow offscreen.
    @MainActor
    @Test func legacyDividersExpandToHideItems() {
        for divider in dividers {
            #expect(divider.length(for: .hideSection, usesNativeBackend: false) == 10_000)
            #expect(divider.length(for: .showSection, usesNativeBackend: false) == NSStatusItem.variableLength)
        }
    }

    // The native backend (macOS 27) hides items itself, so a collapsed divider must take
    // up no space. `nil`, not zero: a zero length still leaves a blank gap, because the
    // item's content view keeps its minimum width until that constraint is removed (#120).
    @MainActor
    @Test func nativeCollapsedDividersTakeNoSpace() {
        for divider in dividers {
            #expect(divider.length(for: .hideSection, usesNativeBackend: true) == nil)
            #expect(divider.length(for: .showSection, usesNativeBackend: true) == NSStatusItem.variableLength)
        }
    }

    @MainActor
    @Test func iceIconAlwaysHasStandardLength() {
        for usesNativeBackend in [false, true] {
            for state in [ControlItem.HidingState.showSection, .hideSection] {
                let length = ControlItem.Identifier.visible.length(for: state, usesNativeBackend: usesNativeBackend)
                #expect(length == NSStatusItem.variableLength)
            }
        }
    }
}
