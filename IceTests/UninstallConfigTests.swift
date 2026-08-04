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
/// contract is asserted here rather than trusted to review: the domain that gets wiped, every
/// path removed alongside it, the checklist the user is shown, and — just as importantly —
/// that all of it stays scoped to the *running* bundle id.
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
            // The caches/support folders `extraCleanupPaths` adds are deleted, so the
            // confirmation has to say so — the sheet must not under-report the damage.
            "Caches and support files",
        ])
    }

    @Test func removesThePerBundleLibraryFolders() {
        // The three folders the shared teardown can't infer, matching the manual `rm -rf` in
        // README.md and the Homebrew cask's `zap trash:`. Pinned exactly — and in order — so
        // widening or narrowing an unrecoverable delete has to be a deliberate edit here.
        let library = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library")
        #expect(config.extraCleanupPaths == [
            library.appending(path: "Application Support/\(config.bundleID)"),
            library.appending(path: "Caches/\(config.bundleID)"),
            library.appending(path: "HTTPStorages/\(config.bundleID)"),
        ])
    }

    @Test func scopesEveryCleanupPathToTheRunningBundle() {
        // The guardrail behind `wipesTheRunningBundlesDomain`: a debug build
        // (com.dragonapp.ice.debug) must never delete the installed release's caches, so every
        // path has to be built from the *running* bundle id and stay inside ~/Library.
        let library = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library")
        for url in config.extraCleanupPaths {
            // Each folder is named for the running bundle id...
            #expect(url.lastPathComponent == Bundle.main.bundleIdentifier)
            // ...and sits under this user's ~/Library, never anywhere else on disk.
            #expect(url.path.hasPrefix(library.path + "/"))
        }
    }

    @Test func deletesNothingBeyondTheBundlesOwnFolders() {
        // Ice 2's settings live in `UserDefaults.standard` (`Defaults.store`), i.e. the
        // bundle-id domain the uninstaller already wipes — so no extra suites.
        #expect(config.suiteNames.isEmpty)
        // Ice 2 keeps no separate user data — its settings *are* its data, always removed —
        // so there is no optional "also delete data" choice to opt into.
        #expect(config.optionalDataToggle == nil)
    }
}
