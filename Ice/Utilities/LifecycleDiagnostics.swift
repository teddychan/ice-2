//
//  LifecycleDiagnostics.swift
//  Ice
//

import AppKit
import OSLog

/// Temporary instrumentation for diagnosing unexplained app exits.
///
/// The app has been observed vanishing without AppKit's usual termination
/// sequence and without a crash report. These hooks record just enough context
/// to tell the candidate causes apart. Read the results as a truth table:
///
/// * `Launch` present, nothing after it — the process was killed by a signal
///   (`SIGTERM` from `pkill`/`killall`, or `SIGKILL`). `atexit` handlers do not
///   run for signal deaths, so the absence of `Exiting process` is the tell.
/// * `Exiting process` without `Termination requested` — something called
///   `exit()` directly, bypassing `NSApplication.terminate`.
/// * `Termination requested` — an orderly quit. The line names the Apple Event
///   sender when the request arrived from another process.
/// * `Uncaught exception` — an Objective-C exception unwound out of the app.
///
/// The `Launch` line also records whether this process is a test host or a
/// SwiftUI preview, either of which returns early from
/// `applicationDidFinishLaunching` and so never performs setup.
enum LifecycleDiagnostics {
    private static let logger = Logger(category: "Lifecycle")

    /// The time this process began running, used to report how long it
    /// survived when it exits.
    private static let launchDate = Date()

    /// `keySenderPIDAttr` ('spid'), which Swift's Apple Event overlay does
    /// not surface as a constant.
    private static let senderPIDAttribute = AEKeyword(0x7370_6964)

    // MARK: Installation

    /// Installs the diagnostic hooks.
    ///
    /// Call as early as possible during launch. Exits that happen before this
    /// runs — for example while ``AppState`` is being constructed — are not
    /// covered.
    static func install() {
        _ = launchDate
        logLaunchContext()
        installExitHandler()
        installUncaughtExceptionHandler()
    }

    /// Logs the identity and launch environment of this process.
    ///
    /// The bundle path matters because a debug build sharing the release
    /// bundle identifier collides with the installed app on TCC grants and the
    /// preferences domain, so knowing *which* binary produced a line is the
    /// first thing to establish.
    private static func logLaunchContext() {
        let processInfo = ProcessInfo.processInfo
        let bundle = Bundle.main
        let environment = processInfo.environment

        let isTestHost = environment["XCTestConfigurationFilePath"] != nil
        let isPreview = environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

        logger.notice("""
            Launch: pid \(processInfo.processIdentifier, privacy: .public), \
            ppid \(getppid(), privacy: .public) (\(parentDescription(), privacy: .public)), \
            bundle \(bundle.bundleIdentifier ?? "nil", privacy: .public) \
            v\(shortVersion(), privacy: .public) (\(buildVersion(), privacy: .public)), \
            path \(bundle.bundleURL.path, privacy: .public), \
            testHost \(isTestHost, privacy: .public), \
            preview \(isPreview, privacy: .public), \
            args \(processInfo.arguments.dropFirst().joined(separator: " "), privacy: .public)
            """)

        logOtherInstances()
    }

    /// Logs any other running process that claims this bundle identifier.
    ///
    /// Two instances sharing an identifier is the collision that makes the
    /// system treat a debug build and the installed app as the same app.
    private static func logOtherInstances() {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return
        }
        let others = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }

        guard !others.isEmpty else {
            logger.notice("No other instance of \(bundleID, privacy: .public) is running")
            return
        }
        for other in others {
            logger.error("""
                Another instance shares this bundle identifier: \
                pid \(other.processIdentifier, privacy: .public) at \
                \(other.bundleURL?.path ?? "unknown path", privacy: .public)
                """)
        }
    }

    /// Registers an `atexit` handler that reports the exit and the stack that
    /// caused it.
    private static func installExitHandler() {
        atexit {
            // Runs for exit() but not for signal deaths, which is what makes
            // this line a useful discriminator.
            LifecycleDiagnostics.logExit()
        }
    }

    /// Logs the exit and the call stack that reached it.
    private static func logExit() {
        let lifetime = Date().timeIntervalSince(launchDate)
        logger.error("""
            Exiting process \(ProcessInfo.processInfo.processIdentifier, privacy: .public) \
            after \(String(format: "%.3f", lifetime), privacy: .public)s
            """)
        logCallStack(label: "exit")
    }

    /// The exception handler that was in place before ours, held in storage
    /// because a C function pointer cannot capture it.
    private nonisolated(unsafe) static var previousExceptionHandler: (@convention(c) (NSException) -> Void)?

    /// Installs an uncaught exception handler that logs before deferring to
    /// whatever handler was already in place.
    private static func installUncaughtExceptionHandler() {
        previousExceptionHandler = NSGetUncaughtExceptionHandler()
        NSSetUncaughtExceptionHandler { exception in
            LifecycleDiagnostics.logUncaughtException(exception)
            LifecycleDiagnostics.previousExceptionHandler?(exception)
        }
    }

    /// Logs an uncaught Objective-C exception and where it came from.
    private static func logUncaughtException(_ exception: NSException) {
        logger.error("""
            Uncaught exception \(exception.name.rawValue, privacy: .public): \
            \(exception.reason ?? "no reason", privacy: .public)
            """)
        logger.error("""
            Exception stack:
            \(exception.callStackSymbols.joined(separator: "\n"), privacy: .public)
            """)
    }

    // MARK: Reporting

    /// Logs that termination was requested, naming the requester when the
    /// request came in as an Apple Event from another process.
    static func logTerminationRequest() {
        logger.notice("Termination requested: \(terminationRequestOrigin(), privacy: .public)")
        logCallStack(label: "termination request")
    }

    /// Logs an explicit self-relaunch, which quits this instance on purpose
    /// and so would otherwise look like an unexplained exit.
    static func logRelaunch() {
        logger.notice("Relaunching from \(Bundle.main.bundleURL.path, privacy: .public)")
        logCallStack(label: "relaunch")
    }

    /// Describes where a termination request originated.
    private static func terminationRequestOrigin() -> String {
        guard let event = NSAppleEventManager.shared().currentAppleEvent else {
            return "no current Apple Event (requested from within this process)"
        }
        var description = """
            Apple Event \(fourCharCodeString(event.eventClass))/\
            \(fourCharCodeString(event.eventID))
            """
        guard
            let senderPID = event.attributeDescriptor(forKeyword: senderPIDAttribute)?.int32Value,
            senderPID != 0
        else {
            return description + " from an unidentified sender"
        }
        description += " from pid \(senderPID)"
        if let sender = NSRunningApplication(processIdentifier: senderPID) {
            let name = sender.localizedName ?? "unnamed"
            let senderBundleID = sender.bundleIdentifier ?? "no bundle identifier"
            description += " (\(name), \(senderBundleID))"
        }
        return description
    }

    /// Logs the current call stack under the given label.
    ///
    /// One frame per line: a whole stack in a single message runs into
    /// `os_log`'s size limit and gets truncated exactly where the interesting
    /// frames start. The leading frames belong to this file and to the logging
    /// machinery itself, so they are dropped.
    private static func logCallStack(label: String) {
        let frames = Array(
            Thread.callStackSymbols
                .drop { $0.contains("LifecycleDiagnostics") || $0.contains("OSLog") }
                .prefix(16)
        )
        logger.error("""
            Call stack at \(label, privacy: .public) \
            (\(frames.count, privacy: .public) frames):
            """)
        for (index, frame) in frames.enumerated() {
            logger.error("  \(index, privacy: .public): \(frame, privacy: .public)")
        }
    }

    // MARK: Helpers

    /// Returns a description of the parent process, which identifies what
    /// launched this instance.
    private static func parentDescription() -> String {
        let parentPID = getppid()
        if let parent = NSRunningApplication(processIdentifier: parentPID) {
            return parent.localizedName ?? parent.bundleIdentifier ?? "unnamed app"
        }
        return parentPID == 1 ? "launchd" : "not an application"
    }

    /// Returns the marketing version of this build.
    private static func shortVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    /// Returns the build number of this build.
    private static func buildVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    }

    /// Converts a four character code into a readable string.
    private static func fourCharCodeString(_ code: FourCharCode) -> String {
        let bytes = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF),
        ]
        guard bytes.allSatisfy({ $0 >= 0x20 && $0 < 0x7F }) else {
            return String(format: "0x%08X", code)
        }
        return String(bytes.map { Character(UnicodeScalar($0)) })
    }
}
