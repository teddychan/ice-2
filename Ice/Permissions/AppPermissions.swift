//
//  AppPermissions.swift
//  Ice
//

import AppKit
import Combine
import Foundation
import OSLog

/// A type that manages the permissions of the app.
@MainActor
final class AppPermissions: ObservableObject {
    /// Keys to access individual permissions.
    enum PermissionKey {
        case accessibility
        case screenRecording
    }

    /// The state of the app's granted permissions.
    enum PermissionsState {
        case missing
        case hasAll
        case hasRequired
    }

    /// The manager's logger.
    let logger = Logger(category: "Permissions")

    /// The permission for Accessibility features.
    let accessibility = AccessibilityPermission()

    /// The permission for Screen Recording features.
    let screenRecording = ScreenRecordingPermission()

    /// The state of the app's granted permissions.
    @Published private(set) var permissionsState: PermissionsState = .missing

    /// Storage for internal observers.
    private var cancellable: AnyCancellable?

    /// Observer that re-checks permissions when the app becomes active.
    private var activationCancellable: AnyCancellable?

    /// The permissions required for full app functionality.
    var allPermissions: [Permission] {
        [accessibility, screenRecording]
    }

    /// The permissions required for basic app functionality.
    var requiredPermissions: [Permission] {
        allPermissions.filter { $0.isRequired }
    }

    /// Creates a new permissions manager.
    init() {
        self.updatePermissionsState()
        self.cancellable = Publishers.MergeMany(allPermissions.map { $0.$hasPermission })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePermissionsState()
            }
        // Re-check permissions when the app becomes active (e.g. the user
        // returns after granting/revoking in System Settings). This replaces
        // the old always-on per-permission 1s poll, so a granted app does no
        // permission work while idle.
        self.activationCancellable = NotificationCenter.default
            .publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.refreshAllPermissions()
            }
    }

    /// Updates the current permissions state.
    private func updatePermissionsState() {
        let newState: PermissionsState
        if allPermissions.allSatisfy({ $0.hasPermission }) {
            newState = .hasAll
        } else if requiredPermissions.allSatisfy({ $0.hasPermission }) {
            newState = .hasRequired
        } else {
            newState = .missing
        }
        // Only publish on an actual change, to avoid churning observers.
        if permissionsState != newState {
            permissionsState = newState
        }
    }

    /// Refreshes all tracked permission values.
    func refreshAllPermissions() {
        for permission in allPermissions {
            permission.refresh()
        }
        updatePermissionsState()
    }

    /// Stops running all permissions checks.
    func stopAllChecks() {
        logger.info("Stopping all permissions checks")
        for permission in allPermissions {
            permission.stopCheck()
        }
    }
}
