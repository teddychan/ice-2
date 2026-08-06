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
        let wait = try #require(script.range(of: "while kill -0 4242 2>/dev/null; do sleep 0.1; done"))
        let open = try #require(script.range(of: "/usr/bin/open"))
        #expect(wait.upperBound <= open.lowerBound)
    }

    @Test func forcesANewInstanceInsteadOfResolvingTheBundleID() {
        // More than one bundle can claim a given id — stale builds in other
        // DerivedData folders do — and plain `open` would let LaunchServices pick.
        // `-n` opens the bundle at the path we were given.
        #expect(arguments()[1].contains("open -n"))
    }
}
