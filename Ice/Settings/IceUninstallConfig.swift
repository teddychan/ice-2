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
/// by DragonKit. Everything Ice 2 writes lives in its `UserDefaults` domain (`Defaults.store`
/// is `.standard`) plus its saved application state, both of which the shared teardown
/// removes from `bundleID`, so there are no extra suites and no extra cleanup paths. Ice 2
/// keeps no separate user data either — its settings *are* its data, always removed — so
/// there is no optional "also delete data" toggle, unlike ClipMenu.
enum IceUninstallConfig {
    static var config: UninstallConfig {
        UninstallConfig(
            appName: "Ice 2",
            // The running bundle's id, so a debug build (com.dragonapp.ice.debug) cleans its
            // OWN domain/state and never the installed release's.
            bundleID: Bundle.main.bundleIdentifier ?? "com.dragonapp.ice",
            checklistItems: [
                "The app and its login item",
                "Settings, layout profiles, and hotkeys",
                "Saved application state",
            ]
        )
    }
}
