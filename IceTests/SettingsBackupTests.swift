//
//  SettingsBackupTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

struct SettingsBackupTests {
    /// A throwaway UserDefaults suite. Caller must clean it up (see `defer`).
    private func makeScratch() -> (defaults: UserDefaults, suite: String) {
        let suite = "IceTests." + UUID().uuidString
        return (UserDefaults(suiteName: suite)!, suite)
    }

    @Test func payloadRoundTripReproducesValues() {
        let (source, sSuite) = makeScratch()
        let (target, tSuite) = makeScratch()
        defer {
            UserDefaults.standard.removePersistentDomain(forName: sSuite)
            UserDefaults.standard.removePersistentDomain(forName: tSuite)
        }
        source.set("hello", forKey: Defaults.Key.iceIcon.rawValue)
        source.set(42, forKey: Defaults.Key.showOnHoverDelay.rawValue)

        let payload = SettingsBackup.makePayload(
            from: source, appVersion: "9.9", createdDate: Date(timeIntervalSince1970: 1000)
        )
        SettingsBackup.apply(payload, to: target)

        #expect(target.string(forKey: Defaults.Key.iceIcon.rawValue) == "hello")
        #expect(target.integer(forKey: Defaults.Key.showOnHoverDelay.rawValue) == 42)
    }

    @Test func applyIsReplaceNotMerge() {
        let (source, sSuite) = makeScratch()
        let (target, tSuite) = makeScratch()
        defer {
            UserDefaults.standard.removePersistentDomain(forName: sSuite)
            UserDefaults.standard.removePersistentDomain(forName: tSuite)
        }
        source.set("keep", forKey: Defaults.Key.iceIcon.rawValue)
        // A backed-up key present in target but absent from the payload must be removed.
        target.set(true, forKey: Defaults.Key.useIceBar.rawValue)

        let payload = SettingsBackup.makePayload(
            from: source, appVersion: "1", createdDate: Date(timeIntervalSince1970: 0)
        )
        SettingsBackup.apply(payload, to: target)

        #expect(target.string(forKey: Defaults.Key.iceIcon.rawValue) == "keep")
        #expect(target.object(forKey: Defaults.Key.useIceBar.rawValue) == nil)
    }

    @Test func excludedKeysNeverTravel() {
        let (source, sSuite) = makeScratch()
        defer { UserDefaults.standard.removePersistentDomain(forName: sSuite) }
        source.set("/tmp/x", forKey: Defaults.Key.backupFolderPath.rawValue)
        source.set(true, forKey: Defaults.Key.automaticBackupEnabled.rawValue)

        let payload = SettingsBackup.makePayload(
            from: source, appVersion: "1", createdDate: Date(timeIntervalSince1970: 0)
        )
        // PayloadKey is private -> inspect via the raw string key.
        let stored = payload["defaults"] as? [String: Any] ?? [:]
        #expect(stored[Defaults.Key.backupFolderPath.rawValue] == nil)
        #expect(stored[Defaults.Key.automaticBackupEnabled.rawValue] == nil)
    }

    @Test func serializeDeserializeRoundTrip() throws {
        let (source, sSuite) = makeScratch()
        defer { UserDefaults.standard.removePersistentDomain(forName: sSuite) }
        source.set("v", forKey: Defaults.Key.iceIcon.rawValue)

        let payload = SettingsBackup.makePayload(
            from: source, appVersion: "2.0", createdDate: Date(timeIntervalSince1970: 5)
        )
        let data = try SettingsBackup.serialize(payload)
        let back = try SettingsBackup.deserialize(data)

        #expect(SettingsBackup.appVersion(of: back) == "2.0")
        #expect(SettingsBackup.createdDate(of: back) == Date(timeIntervalSince1970: 5))
    }

    @Test func deserializeRejectsNewerSchema() throws {
        let payload: [String: Any] = [
            "schemaVersion": SettingsBackup.schemaVersion + 1,
            "defaults": [String: Any](),
        ]
        let data = try SettingsBackup.serialize(payload)
        #expect(throws: SettingsBackup.BackupError.unsupportedVersion(SettingsBackup.schemaVersion + 1)) {
            _ = try SettingsBackup.deserialize(data)
        }
    }

    @Test func deserializeRejectsValidNonDictionaryPlist() throws {
        // A VALID plist that is an array, not a dictionary — exercises the
        // `as? [String: Any]` guard (random bytes would fail parsing first).
        let data = try PropertyListSerialization.data(
            fromPropertyList: ["a", "b"], format: .binary, options: 0
        )
        #expect(throws: SettingsBackup.BackupError.malformed) {
            _ = try SettingsBackup.deserialize(data)
        }
    }

    @Test func fileNameShapeIsTimezoneRobust() {
        // timestamp() sets no timeZone, so only assert the SHAPE, not an
        // exact value from an absolute Date.
        let name = SettingsBackup.fileName(for: Date(timeIntervalSince1970: 0))
        let matched = name.range(
            of: #"^Ice-Settings-\d{4}-\d{2}-\d{2}-\d{6}\.icebackup$"#,
            options: .regularExpression
        )
        #expect(matched != nil)
    }

    @Test func listBackupsFiltersAndSortsNewestFirst() throws {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: "IceTests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        for stamp in ["2026-01-01-000000", "2026-01-02-000000", "2026-01-03-000000"] {
            try Data("x".utf8).write(to: folder.appending(path: "Ice-Settings-\(stamp).icebackup"))
        }
        try Data("y".utf8).write(to: folder.appending(path: "notes.txt")) // must be ignored

        let list = SettingsBackup.listBackups(in: folder)
        #expect(list.count == 3)
        #expect(list.first?.lastPathComponent == "Ice-Settings-2026-01-03-000000.icebackup")
    }

    @Test func pruneKeepsNewest() throws {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: "IceTests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        for stamp in ["2026-01-01-000000", "2026-01-02-000000", "2026-01-03-000000"] {
            try Data("x".utf8).write(to: folder.appending(path: "Ice-Settings-\(stamp).icebackup"))
        }
        SettingsBackup.prune(in: folder, keeping: 1)

        let remaining = SettingsBackup.listBackups(in: folder)
        #expect(remaining.count == 1)
        #expect(remaining.first?.lastPathComponent == "Ice-Settings-2026-01-03-000000.icebackup")
    }
}
