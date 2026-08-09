//
//  Defaults.swift
//  Ice
//

import Foundation

enum Defaults {
    /// The backing store for all reads and writes. Defaults to
    /// `.standard`; overridable in tests to point at a throwaway suite.
    nonisolated(unsafe) static var store: UserDefaults = .standard

    /// Returns a dictionary containing the keys and values for
    /// the defaults meant to be seen by all applications.
    static var globalDomain: [String: Any] {
        store.persistentDomain(forName: UserDefaults.globalDomain) ?? [:]
    }

    /// Returns the object for the specified key.
    ///
    /// - Parameter key: The key in the UserDefaults database
    ///   to retrieve the value for.
    static func object(forKey key: Key) -> Any? {
        store.object(forKey: key.rawValue)
    }

    /// Returns the string for the specified key.
    ///
    /// - Parameter key: The key in the UserDefaults database
    ///   to retrieve the value for.
    static func string(forKey key: Key) -> String? {
        store.string(forKey: key.rawValue)
    }

    /// Returns the array for the specified key.
    ///
    /// - Parameter key: The key in the UserDefaults database
    ///   to retrieve the value for.
    static func array(forKey key: Key) -> [Any]? {
        store.array(forKey: key.rawValue)
    }

    /// Returns the dictionary for the specified key.
    ///
    /// - Parameter key: The key in the UserDefaults database
    ///   to retrieve the value for.
    static func dictionary(forKey key: Key) -> [String: Any]? {
        store.dictionary(forKey: key.rawValue)
    }

    /// Returns the data for the specified key.
    ///
    /// - Parameter key: The key in the UserDefaults database
    ///   to retrieve the value for.
    static func data(forKey key: Key) -> Data? {
        store.data(forKey: key.rawValue)
    }

    /// Returns the string array for the specified key.
    ///
    /// - Parameter key: The key in the UserDefaults database
    ///   to retrieve the value for.
    static func stringArray(forKey key: Key) -> [String]? {
        store.stringArray(forKey: key.rawValue)
    }

    /// Returns the integer value for the specified key.
    ///
    /// - Parameter key: The key in the UserDefaults database
    ///   to retrieve the value for.
    static func integer(forKey key: Key) -> Int {
        store.integer(forKey: key.rawValue)
    }

    /// Returns the single precision floating point value for
    /// the specified key.
    ///
    /// - Parameter key: The key in the UserDefaults database
    ///   to retrieve the value for.
    static func float(forKey key: Key) -> Float {
        store.float(forKey: key.rawValue)
    }

    /// Returns the double precision floating point value for
    /// the specified key.
    ///
    /// - Parameter key: The key in the UserDefaults database
    ///   to retrieve the value for.
    static func double(forKey key: Key) -> Double {
        store.double(forKey: key.rawValue)
    }

    /// Returns the Boolean value for the specified key.
    ///
    /// - Parameter key: The key in the UserDefaults database
    ///   to retrieve the value for.
    static func bool(forKey key: Key) -> Bool {
        store.bool(forKey: key.rawValue)
    }

    /// Returns the url for the specified key.
    ///
    /// - Parameter key: The key in the UserDefaults database
    ///   to retrieve the value for.
    static func url(forKey key: Key) -> URL? {
        store.url(forKey: key.rawValue)
    }

    /// Sets the value for the specified key.
    ///
    /// - Parameter key: The key in the UserDefaults database
    ///   to set the value for.
    static func set(_ value: Any?, forKey key: Key) {
        store.set(value, forKey: key.rawValue)
    }

    /// Removes the value of the specified key.
    ///
    /// - Parameter key: The key in the UserDefaults database
    ///   to remove the value for.
    static func removeObject(forKey key: Key) {
        store.removeObject(forKey: key.rawValue)
    }

    /// Retrieves the value for the given key, and, if it is
    /// present, assigns it to the given `inout` parameter.
    static func ifPresent<Value>(key: Key, assign value: inout Value) {
        if let found = object(forKey: key) as? Value {
            value = found
        }
    }

    /// Retrieves the value for the given key, and, if it is
    /// present, performs the given closure.
    static func ifPresent<Value>(key: Key, body: (Value) throws -> Void) rethrows {
        if let found = object(forKey: key) as? Value {
            try body(found)
        }
    }
}

extension Defaults {
    enum Key: String, CaseIterable {
        // MARK: General Settings
        case showIceIcon = "ShowIceIcon"
        case iceIcon = "IceIcon"
        case customIceIconIsTemplate = "CustomIceIconIsTemplate"
        case useIceBar = "UseIceBar"
        case autoEnableIceBar = "AutoEnableIceBar"
        case iceBarAutoEnableMode = "IceBarAutoEnableMode"
        case iceBarDisplayWidthThreshold = "IceBarDisplayWidthThreshold"
        case iceBarLocation = "IceBarLocation"
        case showOnClick = "ShowOnClick"
        case showOnHover = "ShowOnHover"
        case showOnHoverDelay = "ShowOnHoverDelay"
        case showOnHoverOverIceIcon = "ShowOnHoverOverIceIcon"
        case showOnHoverOverIceIconDelay = "ShowOnHoverOverIceIconDelay"
        case showOnScroll = "ShowOnScroll"
        case autoRehide = "AutoRehide"
        case rehideStrategy = "RehideStrategy"
        case rehideInterval = "RehideInterval"
        case itemSpacingOffset = "ItemSpacingOffset"
        case menuBarLayoutProfiles = "MenuBarLayoutProfiles"
        case menuBarSpacers = "MenuBarSpacers"
        case menuBarTriggers = "MenuBarTriggers"

        // MARK: Hotkeys Settings
        case hotkeys = "Hotkeys"

        // MARK: Advanced Settings
        case enableAlwaysHiddenSection = "EnableAlwaysHiddenSection"
        case showAllSectionsOnUserDrag = "ShowAllSectionsOnUserDrag"
        case sectionDividerStyle = "SectionDividerStyle"
        case hideApplicationMenus = "HideApplicationMenus"
        case enableSecondaryContextMenu = "EnableSecondaryContextMenu"
        case tempShowInterval = "TempShowInterval"

        // MARK: Appearance Settings
        case menuBarAppearanceConfigurationV2 = "MenuBarAppearanceConfigurationV2"

        // MARK: Backup & Restore (meta-settings; excluded from the backup payload)
        case backupFolderPath = "BackupFolderPath"
        case automaticBackupEnabled = "AutomaticBackupEnabled"

        // MARK: Local State (not settings; excluded from the backup payload)
        // A record of which menu bar items have appeared on this Mac, used to
        // tell a newly created item from one the user has already arranged.
        case knownMenuBarItems = "KnownMenuBarItems"

        // MARK: Deprecated (Advanced Settings)
        case showSectionDividers = "ShowSectionDividers"
        case canToggleAlwaysHiddenSection = "CanToggleAlwaysHiddenSection"

        // MARK: Deprecated (Other)
        case sections = "Sections"
        // Item groups were removed in 2.12.0. The key is kept so `AppSettings`
        // can delete the leftover blob from existing installs, and so a restore
        // can't put it back.
        case menuBarItemGroups = "MenuBarItemGroups"
    }
}
