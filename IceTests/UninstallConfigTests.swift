//
//  UninstallConfigTests.swift
//  IceTests
//

import DragonKit
import Foundation
import Testing
@testable import Ice_2

/// Pins the configuration Ice 2 hands to DragonKit's uninstaller. This is the seam where a
/// mistake silently changes what a destructive, unrecoverable operation deletes, so the
/// contract is asserted here rather than trusted to review: the domain that gets wiped, the
/// checklist the user is shown, and — just as importantly — that nothing *extra* is deleted.
struct UninstallConfigTests {
    private var config: UninstallConfig { IceUninstallConfig.config }

    @Test func wipesTheRunningBundlesDomain() {
        // The running bundle's id, never a hardcoded release id: a debug build
        // (com.dragonapp.ice.debug) must clean its own domain and saved state, and must
        // never touch the installed release's.
        #expect(config.bundleID == Bundle.main.bundleIdentifier)
        #expect(!config.bundleID.isEmpty)
    }

    @Test func namesExactlyWhatIsRemoved() {
        #expect(config.appName == "Ice 2")
        #expect(config.checklistItems == [
            "The app and its login item",
            "Settings, layout profiles, and hotkeys",
            "Saved application state",
        ])
    }

    @Test func deletesNothingBeyondTheBundlesOwnDomain() {
        // Ice 2's settings live in `UserDefaults.standard` (`Defaults.store`), i.e. the
        // bundle-id domain the uninstaller already wipes — so no extra suites.
        #expect(config.suiteNames.isEmpty)
        // No support files or caches outside that domain, so nothing else is removed.
        #expect(config.extraCleanupPaths.isEmpty)
        // Ice 2 keeps no separate user data — its settings *are* its data, always removed —
        // so there is no optional "also delete data" choice to opt into.
        #expect(config.optionalDataToggle == nil)
    }
}
