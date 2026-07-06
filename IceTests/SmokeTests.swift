//
//  SmokeTests.swift
//  IceTests
//

import Testing
// The Ice app target's product name is "Ice 2", so its Swift module is `Ice_2`.
@testable import Ice_2

/// Proves the test target links against the Ice app host and that
/// `@testable import Ice_2` resolves the app's internal types.
struct SmokeTests {
    @Test func iceModuleIsImportable() {
        #expect(MenuBarSection.Name.allCases.count == 3)
    }
}
