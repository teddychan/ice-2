//
//  SettingsBackup.swift
//  Ice
//

import Foundation

/// Folder-based backup & restore of all of Ice's settings.
///
/// Ice keeps every user setting in `UserDefaults.standard` under the keys in
/// `Defaults.Key` — including the Codable blobs (layout profiles, item groups,
/// spacers, triggers, appearance config, hotkeys), which are stored as raw
/// `Data`. A backup is therefore just a snapshot of those keys written to a
/// property-list file; a restore writes them back and relaunches. This sidesteps
/// decoding every Codable type and picks up any future key automatically.
///
/// Ice is distributed via Developer ID (not sandboxed), so it can read and write
/// any folder the user picks — point the backup folder at Dropbox, iCloud Drive,
/// or Google Drive to sync settings across Macs.
///
/// All of the logic here is pure / injectable (takes a `UserDefaults` and folder
/// URL) so it can be exercised without the running app.
enum SettingsBackup {
    /// Bumped only if the on-disk format changes incompatibly.
    static let schemaVersion = 1

    /// File extension for backup files.
    static let fileExtension = "icebackup"

    /// Keys NOT included in a backup: deprecated keys (so a restore can't
    /// resurrect state the app has migrated away from) and the backup feature's
    /// own meta-settings (which are machine-specific and shouldn't travel).
    static let excludedKeys: Set<Defaults.Key> = [
        .showSectionDividers, .canToggleAlwaysHiddenSection, .sections,
        .backupFolderPath, .automaticBackupEnabled,
    ]

    /// The settings keys carried in a backup.
    static var backedUpKeys: [Defaults.Key] {
        Defaults.Key.allCases.filter { !excludedKeys.contains($0) }
    }

    enum BackupError: Error, Equatable {
        case malformed
        case unsupportedVersion(Int)
    }

    private enum PayloadKey {
        static let schemaVersion = "schemaVersion"
        static let appVersion = "appVersion"
        static let createdDate = "createdDate"
        static let defaults = "defaults"
    }

    // MARK: - Snapshot / apply (pure)

    /// Build a backup payload from the values currently stored under `keys`.
    /// Only keys that actually have a stored value are included.
    static func makePayload(
        keys: [Defaults.Key] = backedUpKeys,
        from defaults: UserDefaults,
        appVersion: String,
        createdDate: Date
    ) -> [String: Any] {
        var stored: [String: Any] = [:]
        for key in keys {
            if let value = defaults.object(forKey: key.rawValue) {
                stored[key.rawValue] = value
            }
        }
        return [
            PayloadKey.schemaVersion: schemaVersion,
            PayloadKey.appVersion: appVersion,
            PayloadKey.createdDate: createdDate,
            PayloadKey.defaults: stored,
        ]
    }

    /// Apply a payload's stored values onto `defaults`. For every backed-up key
    /// the stored value replaces the current one; a key absent from the backup is
    /// removed, so a restore reproduces the backup exactly (a replace, not a
    /// merge). Keys outside `keys` (unrelated app/global defaults) are untouched.
    static func apply(
        _ payload: [String: Any],
        to defaults: UserDefaults,
        keys: [Defaults.Key] = backedUpKeys
    ) {
        let stored = payload[PayloadKey.defaults] as? [String: Any] ?? [:]
        for key in keys {
            if let value = stored[key.rawValue] {
                defaults.set(value, forKey: key.rawValue)
            } else {
                defaults.removeObject(forKey: key.rawValue)
            }
        }
    }

    /// The date a payload was created, if present.
    static func createdDate(of payload: [String: Any]) -> Date? {
        payload[PayloadKey.createdDate] as? Date
    }

    /// The app version recorded in a payload, if present.
    static func appVersion(of payload: [String: Any]) -> String? {
        payload[PayloadKey.appVersion] as? String
    }

    // MARK: - Serialize (pure)

    static func serialize(_ payload: [String: Any]) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: payload, format: .binary, options: 0)
    }

    /// Parse a backup file's data and validate its schema version.
    static func deserialize(_ data: Data) throws -> [String: Any] {
        let object = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let payload = object as? [String: Any] else {
            throw BackupError.malformed
        }
        let version = payload[PayloadKey.schemaVersion] as? Int ?? 0
        guard version <= schemaVersion else {
            throw BackupError.unsupportedVersion(version)
        }
        return payload
    }

    // MARK: - Files & retention

    /// Default backup folder when the user hasn't chosen one: ~/Documents/Ice Backups.
    static func defaultFolder(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        home.appending(path: "Documents/Ice Backups", directoryHint: .isDirectory)
    }

    /// A lexically-sortable timestamp, e.g. "2026-06-29-013045".
    static func timestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: date)
    }

    /// Backup filename for a date, e.g. "Ice-Settings-2026-06-29-013045.icebackup".
    static func fileName(for date: Date) -> String {
        "Ice-Settings-\(timestamp(date)).\(fileExtension)"
    }

    /// Write a backup of `defaults` into `folder` (created if needed) and return
    /// the file URL.
    @discardableResult
    static func writeBackup(
        of defaults: UserDefaults,
        to folder: URL,
        appVersion: String,
        date: Date
    ) throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let payload = makePayload(from: defaults, appVersion: appVersion, createdDate: date)
        let data = try serialize(payload)
        let url = folder.appending(path: fileName(for: date))
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Restore the backup at `url` onto `defaults`. Throws on a malformed or
    /// too-new file; the caller is responsible for relaunching afterwards.
    static func restore(from url: URL, into defaults: UserDefaults) throws {
        let data = try Data(contentsOf: url)
        let payload = try deserialize(data)
        apply(payload, to: defaults)
    }

    /// Existing backup files in `folder`, newest first (filenames sort
    /// chronologically because the timestamp is zero-padded).
    static func listBackups(in folder: URL) -> [URL] {
        let contents = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        return contents
            .filter { $0.pathExtension == fileExtension }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    /// Delete the oldest backups beyond `max`, keeping the newest `max`.
    static func prune(in folder: URL, keeping max: Int) {
        let all = listBackups(in: folder) // newest first
        guard all.count > max else { return }
        for url in all[max...] {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - App conveniences

    /// The newest backups to retain by default.
    static let defaultRetentionLimit = 10

    /// The running app's marketing version, stamped into each backup.
    static var currentAppVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    /// The user-configured backup folder, or `defaultFolder()` when unset.
    static func configuredFolder(_ defaults: UserDefaults = .standard) -> URL {
        if let path = defaults.string(forKey: Defaults.Key.backupFolderPath.rawValue), !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return defaultFolder()
    }

    /// Whether automatic (on-quit) backups are enabled (default true).
    static func automaticBackupEnabled(_ defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: Defaults.Key.automaticBackupEnabled.rawValue) as? Bool ?? true
    }

    /// Back up `defaults` to the configured folder and prune to the retention
    /// limit. Returns the written file URL.
    @discardableResult
    static func performBackup(
        defaults: UserDefaults = .standard,
        appVersion: String = currentAppVersion,
        date: Date,
        keeping max: Int = defaultRetentionLimit
    ) throws -> URL {
        let folder = configuredFolder(defaults)
        let url = try writeBackup(of: defaults, to: folder, appVersion: appVersion, date: date)
        prune(in: folder, keeping: max)
        return url
    }
}
