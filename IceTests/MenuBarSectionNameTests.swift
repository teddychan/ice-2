//
//  MenuBarSectionNameTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

struct MenuBarSectionNameTests {
    // Profile snapshots iterate allCases in order; order is load-bearing.
    @Test func allCasesInDeclaredOrder() {
        #expect(MenuBarSection.Name.allCases == [.visible, .hidden, .alwaysHidden])
    }

    // Raw values must stay stable so profiles saved by older builds decode.
    @Test func rawValuesAreStable() throws {
        let data = try JSONEncoder().encode(
            [MenuBarSection.Name.visible, .hidden, .alwaysHidden]
        )
        let json = String(decoding: data, as: UTF8.self)
        #expect(json == #"["visible","hidden","alwaysHidden"]"#)
    }
}
