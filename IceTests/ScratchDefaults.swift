//
//  ScratchDefaults.swift
//  IceTests
//

import Foundation

/// Throwaway `UserDefaults` suites for tests, and the cleanup that keeps them
/// from piling up in `~/Library/Preferences`.
///
/// Every scratch suite is named `IceTests.<…>.<UUID>`, and `cfprefsd` backs each
/// one with a `<suite>.plist` file. That file cannot be disposed of from inside
/// the test process: `removePersistentDomain(forName:)` empties the domain, but
/// `cfprefsd` still owns it and writes an empty plist back out when the process
/// exits — as does deleting the file by hand, calling `synchronize()`, or
/// `removeSuite(named:)`, in any order. Each run therefore ends with one empty
/// husk per suite it created.
///
/// So cleanup is split in two:
/// - ``destroy(_:)`` clears the domain (the part that actually matters for test
///   isolation) and unlinks the file, which sticks if the process is killed
///   before `cfprefsd`'s exit flush.
/// - ``make(label:)`` sweeps husks left behind by *earlier* runs, once per
///   process. That is what stops unbounded growth: a run inherits a clean
///   directory, so the resting count is one run's worth rather than the sum of
///   every run ever.
enum ScratchDefaults {
    /// Shared root of every scratch suite name, so husks are identifiable.
    private static let root = "IceTests"

    /// An isolated suite backed by a fresh UUID.
    ///
    /// The caller owns cleanup: `defer { ScratchDefaults.destroy(suite) }`.
    /// `label` is an optional middle component to make the suite recognizable.
    static func make(label: String? = nil) -> (defaults: UserDefaults, suite: String) {
        _ = sweptStaleHusks // once per process, before any suite of our own exists
        let suite = [root, label, UUID().uuidString]
            .compactMap { $0 }
            .joined(separator: ".")
        // `UserDefaults(suiteName:)` only returns nil for reserved names.
        return (UserDefaults(suiteName: suite)!, suite)
    }

    /// Empties `suite` and unlinks its backing plist.
    static func destroy(_ suite: String) {
        UserDefaults.standard.removePersistentDomain(forName: suite)
        guard let folder = preferencesFolder else {
            return
        }
        try? FileManager.default.removeItem(at: folder.appending(path: "\(suite).plist"))
    }

    /// Deletes scratch husks from previous runs. Evaluated once per process.
    private static let sweptStaleHusks: Void = {
        guard let folder = preferencesFolder else {
            return
        }
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil
        )) ?? []
        for url in contents where url.pathExtension == "plist"
            && url.lastPathComponent.hasPrefix("\(root).") {
            try? FileManager.default.removeItem(at: url)
        }
    }()

    /// The preferences directory this process reads and writes.
    ///
    /// Resolved through `.libraryDirectory` rather than a hardcoded `~/Library`
    /// so it stays correct if the test host is ever sandboxed (which redirects
    /// preferences into the app's container).
    private static var preferencesFolder: URL? {
        try? FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        .appending(path: "Preferences")
    }
}
