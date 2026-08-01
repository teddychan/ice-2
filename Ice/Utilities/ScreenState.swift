//
//  ScreenState.swift
//  Ice
//

import CoreGraphics

/// A namespace for the current state of the screen.
enum ScreenState {
    /// The session dictionary key that reports the screen lock state. There is
    /// no public API for this, but the key has been stable for many releases.
    private static let screenIsLockedKey = "CGSSessionScreenIsLocked"

    /// Returns a Boolean value that indicates whether the contents of the given
    /// display are currently hidden from the user, either because the display is
    /// asleep or because the screen is locked.
    ///
    /// Nothing drawn on top of the menu bar is visible in this state, so there
    /// is no reason to keep capturing the screen to update it.
    ///
    /// - Parameter displayID: An identifier for the display to check. Displays
    ///   sleep independently, so this must be the display being drawn on. The
    ///   lock state, in contrast, belongs to the session as a whole.
    static func isHidden(for displayID: CGDirectDisplayID) -> Bool {
        if CGDisplayIsAsleep(displayID) != 0 {
            return true
        }
        guard let session = CGSessionCopyCurrentDictionary() as? [String: Any] else {
            return false
        }
        return session[screenIsLockedKey] as? Bool ?? false
    }
}
