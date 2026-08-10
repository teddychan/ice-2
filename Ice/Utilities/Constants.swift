//
//  Constants.swift
//  Ice
//

import Foundation

enum Constants {
    // swiftlint:disable force_unwrapping

    /// The app's bundle identifier.
    static let bundleIdentifier = Bundle.main.bundleIdentifier!

    /// The app's display name.
    static let displayName = Bundle.main.displayName!

    // swiftlint:enable force_unwrapping

    /// The bundle identifier of the installed release, which the local debug build extends with
    /// `.debug`. The *running* build's id is ``bundleIdentifier`` — this one names the other end
    /// of that pair, so use it only to ask which build is which.
    static let releaseBundleIdentifier = "com.dragonapp.ice"

    /// Whether `bundleID` belongs to any build of Ice 2 — the installed release or a `.debug`
    /// build running beside it.
    ///
    /// Ice 2 acts on other running applications in several places: it quits and relaunches every
    /// app with a menu bar item to apply a spacing offset, and it offers the frontmost app as a
    /// section trigger. Each of those treated the *other* Ice build as an unrelated third-party
    /// app, so applying a spacing offset in the debug build terminated the installed release —
    /// which `MAC-APP-RELEASE-LIFECYCLE.md` forbids outright, because the two are required to
    /// survive being run at once. `NSRunningApplication.current` only ever excludes this process.
    ///
    /// One predicate rather than a string comparison repeated per call site: the sites are far
    /// apart, and the next one added is the one that would forget. Matched on a dot boundary, so
    /// an unrelated app whose id merely starts with the same letters is still treated as foreign.
    static func isIceBundleID(_ bundleID: String?) -> Bool {
        guard let bundleID else {
            return false
        }
        return bundleID == releaseBundleIdentifier || bundleID.hasPrefix("\(releaseBundleIdentifier).")
    }
}
