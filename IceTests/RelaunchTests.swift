//
//  RelaunchTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

/// Pins the detached helper command behind ``AppState/relaunch()``.
///
/// A relaunch that quits without reopening leaves the user with no app at all — the
/// exact failure that made "Restore and Relaunch" look like a crash — and it is
/// invisible until someone triggers it. So the command's shape is asserted here
/// rather than trusted to review.
@MainActor
struct RelaunchTests {
    private func arguments(
        bundlePath: String = "/Users/x/Library/Developer/Ice 2 Debug.app",
        pid: Int32 = 4242
    ) -> [String] {
        AppState.relaunchHelperArguments(bundlePath: bundlePath, pid: pid)
    }

    @Test func passesTheBundlePathAsAPositionalArgument() {
        let args = arguments()
        // `sh -c <script> <$0> <$1>`: the path arrives as $1 and is never spliced
        // into the script, so spaces and quotes in it cannot change what runs. The
        // debug bundle's own path contains a space, so this is the normal case.
        #expect(args.count == 4)
        #expect(args[0] == "-c")
        #expect(args[3] == "/Users/x/Library/Developer/Ice 2 Debug.app")
        #expect(!args[1].contains("Ice 2 Debug.app"))
        #expect(args[1].contains("\"$1\""))
    }

    @Test func waitsForTheOldProcessToExitBeforeReopening() throws {
        let script = arguments(pid: 4242)[1]
        // Without the wait, `open` runs while the app is still alive and
        // LaunchServices activates the dying instance instead of starting a new one.
        let wait = try #require(script.range(of: "kill -0 4242 2>/dev/null"))
        let open = try #require(script.range(of: "/usr/bin/open"))
        #expect(wait.upperBound <= open.lowerBound)
    }

    @Test func abandonsTheRelaunchIfTheAppNeverExits() throws {
        let script = arguments(pid: 4242)[1]
        // `NSApp.terminate` is a request, not a guarantee — AppKit can refuse it. When
        // it does, the app stays up and this helper keeps waiting, and an *unbounded*
        // wait then banks the reopen: it fires on whatever eventually ends that PID,
        // which is normally the user quitting deliberately minutes or hours later. The
        // app coming back from a quit it was never asked to come back from is the bug
        // this bound exists to prevent. Giving up instead loses nothing that is not
        // already lost — the relaunch plainly did not happen.
        let giveUp = try #require(script.range(of: "exit 0"))
        let open = try #require(script.range(of: "/usr/bin/open"))
        #expect(giveUp.upperBound <= open.lowerBound)
        #expect(script.contains("\(AppState.relaunchHelperTimeoutTicks)"))
    }

    @Test func forcesANewInstanceInsteadOfResolvingTheBundleID() {
        // More than one bundle can claim a given id — stale builds in other
        // DerivedData folders do — and plain `open` would let LaunchServices pick.
        // `-n` opens the bundle at the path we were given.
        #expect(arguments()[1].contains("open -n"))
    }
}
