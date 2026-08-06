//
//  AppSettings.swift
//  Ice
//

import Combine

/// Top-level model for the app's settings.
@MainActor
final class AppSettings: ObservableObject {
    /// The model for the app's Advanced settings.
    let advanced = AdvancedSettings()

    /// The model for the app's General settings.
    let general = GeneralSettings()

    /// The model for the app's Hotkeys settings.
    let hotkeys = HotkeysSettings()

    /// The model for the app's menu bar layout profile settings.
    let layoutProfiles = MenuBarLayoutProfilesSettings()

    /// The model for menu bar trigger settings.
    let triggers = MenuBarTriggerSettings()

    /// Storage for internal observers.
    private var cancellables = Set<AnyCancellable>()

    /// Performs the initial setup of the settings model.
    func performSetup(with appState: AppState) {
        // Item groups were removed in 2.12.0. Nothing reads this key any more, so
        // without this the blob would sit in every existing user's preferences for
        // good. Removing an absent key is a no-op, so this costs nothing once done.
        Defaults.removeObject(forKey: .menuBarItemGroups)

        advanced.performSetup(with: appState)
        general.performSetup(with: appState)
        hotkeys.performSetup(with: appState)
        layoutProfiles.performSetup(with: appState)
        triggers.performSetup(with: appState)
        configureCancellables()
    }

    private func configureCancellables() {
        var c = Set<AnyCancellable>()

        advanced.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &c)
        general.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &c)
        hotkeys.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &c)
        layoutProfiles.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &c)
        triggers.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &c)

        cancellables = c
    }
}
