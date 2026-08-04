//
//  Updates.swift
//  Ice
//

import DragonKitUpdates
import SwiftUI

/// Manager for app updates.
///
/// Sparkle itself lives in DragonKit's ``DragonUpdater`` (module `DragonKitUpdates`), which
/// every Dragon app shares — same feed handling, same settings, and the same reworded
/// "Ice 2 is up to date" alert. Ice 2 keeps only the app-specific parts here: bringing the
/// app forward so Sparkle's dialogs appear in front, and the debug-build guard.
@MainActor
final class UpdatesManager {
    /// The shared app state.
    private(set) weak var appState: AppState?

    /// The underlying updater. The Updates settings pane observes this directly.
    let updater = DragonUpdater()

    /// Performs the initial setup of the manager.
    func performSetup(with appState: AppState) {
        self.appState = appState
        // `DragonUpdater` creates and starts Sparkle lazily on first use, so touch it here:
        // starting the updater at launch is what lets Sparkle schedule its background update
        // checks, exactly as `SPUStandardUpdaterController(startingUpdater: true)` did.
        _ = updater.canCheckForUpdates
    }

    /// Checks for app updates.
    func checkForUpdates() {
        #if DEBUG
        // Checking for updates hangs in debug mode.
        let alert = NSAlert()
        alert.messageText = "Checking for updates is not supported in debug mode."
        alert.runModal()
        #else
        guard let appState else {
            return
        }
        // Activate the app in case an alert needs to be displayed.
        appState.activate(withPolicy: .regular)
        appState.openWindow(.settings)
        updater.checkForUpdates()
        #endif
    }
}
