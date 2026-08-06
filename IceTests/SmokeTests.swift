//
//  SmokeTests.swift
//  IceTests
//

import Foundation
import Testing
// The Ice app target's product name is "Ice 2", so its Swift module is `Ice_2`.
@testable import Ice_2

/// Proves the test target links against the Ice app host and that
/// `@testable import Ice_2` resolves the app's internal types.
struct SmokeTests {
    @Test func iceModuleIsImportable() {
        #expect(MenuBarSection.Name.allCases.count == 3)
    }

    /// The tests run *inside* the app host, so `UserDefaults.standard` — and every
    /// `.standard` seam the app still reads directly, like `ControlItem`'s storage
    /// wrapper and `SettingsBackup`'s default arguments — resolves to whatever domain
    /// the host bundle claims. If that were the release id, a test run would read and
    /// write the settings of the Ice 2 the user actually has installed.
    ///
    /// The Debug configuration therefore builds the app as `com.dragonapp.ice.debug`,
    /// which is what `scripts/run-debug.sh` already gives manual debug runs. This pins
    /// that: the release domain has to stay unreachable from the suite, so restoring
    /// the release id to the Debug configuration fails here instead of silently.
    ///
    /// Asserted as equality rather than `!= "com.dragonapp.ice"` so it can't pass on a
    /// host with no bundle id at all.
    @Test func testHostNeverOwnsTheReleaseSettingsDomain() {
        #expect(Bundle.main.bundleIdentifier == "com.dragonapp.ice.debug")
    }
}
