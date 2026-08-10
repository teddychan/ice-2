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

    /// The XPC service name the app connects to has to be the identifier the embedded service
    /// bundle actually registers under, and both have to be namespaced per build.
    ///
    /// `MenuBarItemService.name` was the literal `com.dragonapp.ice.MenuBarItemService`, so the
    /// debug build and an installed release asked launchd for one name and could not be trusted
    /// to run side by side. Deriving it from `Bundle.main` fixes the client, but only if the XPC
    /// target's `PRODUCT_BUNDLE_IDENTIFIER` moves with it — the two live in different files and
    /// a mismatch is silent at build time and fatal at runtime (no service, so every menu bar
    /// item loses its source PID). Reading the embedded bundle checks the pair together.
    @Test func serviceNameMatchesTheEmbeddedServiceBundleIdentifier() throws {
        #expect(MenuBarItemService.name == "com.dragonapp.ice.debug.MenuBarItemService")

        let url = Bundle.main.bundleURL
            .appending(path: "Contents/XPCServices/MenuBarItemService.xpc")
        let service = try #require(Bundle(url: url), "the app must embed the XPC service")
        #expect(service.bundleIdentifier == MenuBarItemService.name)
    }

    /// `applyOffset()` relaunches every app with a menu bar item, and a relaunch is a terminate.
    /// The other build of Ice 2 has to be exempt: the lifecycle spec requires that changing a
    /// setting in the debug build never terminates the installed release.
    @Test @MainActor func everyIceBuildIsRecognizedAsOurOwn() {
        #expect(MenuBarItemSpacingManager.isAnIceBundleID("com.dragonapp.ice"))
        #expect(MenuBarItemSpacingManager.isAnIceBundleID("com.dragonapp.ice.debug"))
        // Neither an unrelated app that merely starts with the same letters, nor a missing id.
        #expect(!MenuBarItemSpacingManager.isAnIceBundleID("com.dragonapp.iceberg"))
        #expect(!MenuBarItemSpacingManager.isAnIceBundleID("com.apple.controlcenter"))
        #expect(!MenuBarItemSpacingManager.isAnIceBundleID(nil))
    }
}
