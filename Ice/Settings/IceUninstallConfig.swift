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
    /// The release build's bundle id: the fallback for the running bundle's id below, and the
    /// gate on `homebrewCask`.
    private static let releaseBundleID = "com.dragonapp.ice"

    static var config: UninstallConfig {
        // The running bundle's id, so a debug build (com.dragonapp.ice.debug) cleans its OWN
        // domain/state/caches and never the installed release's.
        let bundleID = Bundle.main.bundleIdentifier ?? releaseBundleID
        let library = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library")
        return UninstallConfig(
            appName: Constants.displayName,
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
            ],
            // Ice 2 ships as the Homebrew cask `ice-2` — the token declared by `Casks/ice-2.rb`
            // in teddychan/homebrew-tap, not inferred from the repo name. Homebrew never watches
            // the filesystem, so an app that deletes itself leaves brew's receipt still claiming
            // the cask is installed and `Caskroom/ice-2/<version>/Ice 2.app` a dangling symlink;
            // `brew install --cask ice-2` then refuses outright — "already installed" — for an app
            // that isn't there, pointing at nothing that would fix it. The kit's detached
            // post-exit shell runs `brew uninstall --cask --force ice-2` to clear that record,
            // *after* the bundle is already in the Trash: `brew uninstall --cask` deletes the app
            // bundle itself, so running it first would make `NSWorkspace.recycle` fail on a bundle
            // that was already gone and raise "Uninstall Incomplete" on an uninstall that worked.
            //
            // Release build only, for the same reason `bundleID` above is the *running* bundle's:
            // a debug build (com.dragonapp.ice.debug) was never installed by brew, and clearing
            // the `ice-2` receipt from one would delete the installed release app, not itself.
            homebrewCask: bundleID == releaseBundleID ? "ice-2" : nil
        )
    }
}
