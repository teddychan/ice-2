//
//  IceUninstallConfig.swift
//  Ice
//

import DragonKit
import Foundation

/// App-owned Uninstall configuration for Ice 2, rendered by DragonKit's
/// ``UninstallSettingsPane`` and performed by ``DragonUninstaller``.
///
/// Only Ice 2's own content lives here — the confirmation layout and the teardown are owned
/// by DragonKit. Ice 2's settings live in its `UserDefaults` domain (`Defaults.store` is
/// `.standard`), which the shared teardown wipes from `bundleID` along with the matching
/// preference plist and saved application state, so there are no extra suites. Ice 2 keeps no
/// separate user data either — its settings *are* its data, always removed — so there is no
/// optional "also delete data" toggle, unlike ClipMenu.
///
/// `extraCleanupPaths` covers the per-bundle-id folders the shared teardown can't know about:
/// the `Caches` and `HTTPStorages` folders macOS creates for the app's own network traffic
/// (Sparkle's appcast fetches), plus `Application Support`. Ice 2 writes nothing to
/// `Application Support` today, but it is listed so the in-app uninstall, the manual `rm -rf`
/// in `README.md`, and the Homebrew cask's `zap trash:` all remove the same five paths —
/// keeping those three from drifting is the point, and removing an absent folder is a no-op.
enum IceUninstallConfig {
    static var config: UninstallConfig {
        // The running bundle's id, so a debug build (com.dragonapp.ice.debug) cleans its OWN
        // domain/state/caches and never the installed release's.
        let bundleID = Bundle.main.bundleIdentifier ?? "com.dragonapp.ice"
        let library = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library")
        return UninstallConfig(
            appName: "Ice 2",
            bundleID: bundleID,
            checklistItems: [
                "The app and its login item",
                "Settings, layout profiles, and hotkeys",
                "Saved application state",
                "Caches and support files",
            ],
            extraCleanupPaths: [
                library.appending(path: "Application Support/\(bundleID)"),
                library.appending(path: "Caches/\(bundleID)"),
                library.appending(path: "HTTPStorages/\(bundleID)"),
            ]
        )
    }
}
