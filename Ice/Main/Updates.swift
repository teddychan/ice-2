//
//  Updates.swift
//  Ice
//

import DragonKitUpdates
import OSLog
import SwiftUI
import UserNotifications

/// Manager for app updates.
///
/// Sparkle itself lives in DragonKit's ``DragonUpdater`` (module `DragonKitUpdates`), which
/// every Dragon app shares — same feed handling, same settings, and the same reworded
/// "Ice 2 is up to date" alert. Ice 2 keeps only the app-specific parts here: bringing the
/// app forward so Sparkle's dialogs appear in front, the debug-build guard, and its own
/// notification for an update a background check found.
@MainActor
final class UpdatesManager {
    /// The shared app state.
    private(set) weak var appState: AppState?

    /// The underlying updater. The Updates settings pane observes this directly.
    ///
    /// Both settings are behaviour Ice 2 had when it wired Sparkle itself and lost when it
    /// moved onto the kit, because ``DragonUpdater`` passed no user-driver delegate at all.
    let updater = DragonUpdater(config: DragonUpdaterConfig(
        // A scheduled check shows Sparkle's window without stealing focus, rather than a modal
        // arriving unprompted while you are working.
        usesGentleScheduledReminders: true,
        onUpdateFoundInBackground: { UpdatesManager.notifyUpdateAvailable() }
    ))

    /// Performs the initial setup of the manager.
    func performSetup(with appState: AppState) {
        self.appState = appState
        // Starting the updater at launch is what lets Sparkle schedule its background update
        // checks, exactly as `SPUStandardUpdaterController(startingUpdater: true)` did.
        updater.start()
        // Only users who turned scheduled checks on can ever see the notification below
        // (`SUEnableAutomaticChecks` is false by default), and only they were prompted before:
        // the old `SPUUpdaterDelegate` hook that requested this fired when Sparkle scheduled a
        // check, which it only does when they are enabled. Don't prompt everyone else.
        if updater.automaticallyChecksForUpdates {
            requestNotificationAuthorization()
        }
    }

    /// Checks for app updates.
    func checkForUpdates() {
        #if DEBUG
        // Checking for updates hangs in debug mode.
        let alert = NSAlert()
        alert.messageText = String(localized: "Checking for updates is not supported in debug mode.")
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

    /// Asks for permission to post ``notifyUpdateAvailable()``.
    private func requestNotificationAuthorization() {
        Task {
            do {
                try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.badge, .alert, .sound])
            } catch {
                Logger.default.error("Failed to request notification authorization: \(error)")
            }
        }
    }

    /// Posts Ice 2's "A new update is available" notification.
    ///
    /// Only ever called for a check the user did not start — ``DragonUpdaterConfig`` filters out
    /// user-initiated ones, since someone who just clicked **Check for Updates…** is already
    /// looking at the result. Because gentle reminders are on, Sparkle shows its update window
    /// *without* activating Ice 2, so on a busy desktop that window can sit unnoticed behind
    /// other apps; this is the nudge.
    ///
    /// Deliberately just the one notification, not the `UserNotificationManager` subsystem this
    /// replaces. Sparkle is always the one showing the update here, so there is no state for a
    /// `UNUserNotificationCenterDelegate` to drive that Sparkle's own window doesn't already
    /// cover, and the two callbacks the old code hung off — clearing a delivered notification
    /// once the update got attention, and naming the version in the body — need parts of
    /// Sparkle's delegate that ``DragonUpdaterConfig`` does not expose.
    private static func notifyUpdateAvailable() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "A new update is available")
        content.body = String(localized: "\(Constants.displayName) found a newer version.")
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "UpdateCheck", content: content, trigger: nil)
        )
    }
}
