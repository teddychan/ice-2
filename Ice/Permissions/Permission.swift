//
//  Permission.swift
//  Ice
//

import Combine
import Cocoa

// MARK: - Permission

/// An object that encapsulates the behavior of checking for and requesting
/// a specific permission for the app.
@MainActor
class Permission: ObservableObject, Identifiable {
    /// A Boolean value that indicates whether the app has this permission.
    @Published private(set) var hasPermission = false

    /// The title of the permission.
    let title: String

    /// Descriptive details for the permission.
    let details: [String]

    /// A Boolean value that indicates if the app can work without this permission.
    let isRequired: Bool

    /// A Boolean value that indicates whether the app may need to relaunch
    /// before this permission becomes usable.
    let mayRequireRelaunch: Bool

    /// The URLs of the settings panes to try to open.
    private let settingsURLs: [URL]

    /// The function that checks permissions.
    private let check: () -> Bool

    /// The function that requests permissions.
    private let request: () -> Void

    /// Observer that runs on a timer to check permissions.
    private var timerCancellable: AnyCancellable?

    /// Observer that observes the ``hasPermission`` property.
    private var hasPermissionCancellable: AnyCancellable?

    /// Creates a permission.
    ///
    /// - Parameters:
    ///   - title: The title of the permission.
    ///   - details: Descriptive details for the permission.
    ///   - isRequired: A Boolean value that indicates if the app can work without this permission.
    ///   - settingsURLs: The URLs of the settings panes to open.
    ///   - check: A function that checks permissions.
    ///   - request: A function that requests permissions.
    init(
        title: String,
        details: [String],
        isRequired: Bool,
        mayRequireRelaunch: Bool = false,
        settingsURLs: [URL] = [],
        check: @escaping () -> Bool,
        request: @escaping () -> Void
    ) {
        self.title = title
        self.details = details
        self.isRequired = isRequired
        self.mayRequireRelaunch = mayRequireRelaunch
        self.settingsURLs = settingsURLs
        self.check = check
        self.request = request
        self.hasPermission = check()
        configureCancellables()
    }

    /// Sets up the internal observers for the permission.
    private func configureCancellables() {
        // Only poll while the permission is missing (e.g. during onboarding).
        // Once granted, the timer stops itself; later changes are picked up on
        // app activation via `AppPermissions`. Permissions can only change in
        // System Settings, so there's no reason to poll once we have the grant.
        guard !hasPermission else {
            return
        }
        timerCancellable = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .merge(with: Just(.now))
            // Deliver asynchronously on the main run loop. Without this, the merged
            // `Just(.now)` fires *synchronously* during `.sink` subscription — before
            // `timerCancellable` is assigned — so `refresh()` sees a nil `timerCancellable`
            // and re-enters `configureCancellables()`, recursing infinitely and crashing at
            // launch whenever the permission isn't already granted. Deferring one run-loop
            // hop lets the assignment complete first, keeping the immediate check + polling.
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                refresh()
            }
    }

    /// Rechecks whether the app has this permission.
    @discardableResult
    func refresh() -> Bool {
        let hasPermission = check()
        // Only publish on an actual change, to avoid waking observers (and
        // churning SwiftUI) every time the check runs.
        if self.hasPermission != hasPermission {
            self.hasPermission = hasPermission
        }
        if hasPermission {
            // Granted — stop polling.
            timerCancellable?.cancel()
            timerCancellable = nil
        } else if timerCancellable == nil {
            // Missing again (e.g. revoked) — resume polling to catch the grant.
            configureCancellables()
        }
        return hasPermission
    }

    /// Performs the request and opens the System Settings app to the appropriate pane.
    func performRequest() {
        request()
        openSettingsPane()
    }

    /// Opens the most relevant System Settings pane for the permission.
    private func openSettingsPane() {
        guard !settingsURLs.isEmpty else {
            return
        }

        if #available(macOS 13, *) {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/System Settings.app"), configuration: configuration)
        }

        if openSettingsURLFallbacks() {
            return
        }

        for settingsURL in settingsURLs {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = [settingsURL.absoluteString]

            do {
                try process.run()
                return
            } catch {
                continue
            }
        }
    }

    /// Attempts to open each settings URL through NSWorkspace.
    private func openSettingsURLFallbacks() -> Bool {
        for settingsURL in settingsURLs where NSWorkspace.shared.open(settingsURL) {
            return true
        }
        return false
    }

    /// Asynchronously waits for the app to be granted this permission.
    func waitForPermission() async {
        configureCancellables()
        guard !hasPermission else {
            return
        }
        return await withCheckedContinuation { continuation in
            hasPermissionCancellable = $hasPermission.sink { [weak self] hasPermission in
                guard let self else {
                    continuation.resume()
                    return
                }
                if hasPermission {
                    hasPermissionCancellable?.cancel()
                    continuation.resume()
                }
            }
        }
    }

    /// Stops running the permission check.
    func stopCheck() {
        timerCancellable?.cancel()
        timerCancellable = nil
        hasPermissionCancellable?.cancel()
        hasPermissionCancellable = nil
    }
}

// MARK: - AccessibilityPermission

final class AccessibilityPermission: Permission {
    init() {
        super.init(
            title: String(localized: "Accessibility"),
            details: [
                String(localized: "Get real-time information about the menu bar."),
                String(localized: "Arrange menu bar items."),
            ],
            isRequired: true,
            mayRequireRelaunch: false,
            settingsURLs: [
                URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"),
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"),
            ].compactMap { $0 },
            check: {
                AXHelpers.isProcessTrusted()
            },
            request: {
                AXHelpers.isProcessTrusted(prompt: true)
            }
        )
    }
}

// MARK: - ScreenRecordingPermission

final class ScreenRecordingPermission: Permission {
    init() {
        super.init(
            title: String(localized: "Screen Recording"),
            details: [
                String(localized: "Change the menu bar's appearance."),
                String(localized: "Display images of individual menu bar items."),
            ],
            isRequired: false,
            mayRequireRelaunch: true,
            settingsURLs: [
                URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture"),
                URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy"),
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"),
            ].compactMap { $0 },
            check: {
                ScreenCapture.checkPermissions()
            },
            request: {
                ScreenCapture.requestPermissions()
            }
        )
    }
}
