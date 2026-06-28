//
//  SourcePIDCache.swift
//  MenuBarItemService
//

import AXSwift
import Cocoa
import Combine
import os

/// A cache for the source process identifiers for menu bar item windows.
///
/// We use the term "source process" to refer to the process that created
/// a menu bar item. Originally, we used the CGWindowList API to get the
/// window's owning process (`kCGWindowOwnerPID`), which was always the
/// source process. However, as of macOS 26, item windows are owned by
/// the Control Center.
///
/// We can find what we need using the Accessibility API, but doing it
/// efficiently ends up being a fairly complex process. Since calls to
/// Accessibility are thread blocking, we do most of the heavy lifting
/// in a dedicated XPC service, which we then call asynchronously from
/// the main app.
final class SourcePIDCache {
    /// An object that contains a running application and provides an
    /// interface to access relevant information, such as its process
    /// identifier and extras menu bar.
    fileprivate final class CachedApplication {
        private let runningApp: NSRunningApplication
        private var extrasMenuBar: UIElement?

        /// The app's process identifier.
        var processIdentifier: pid_t {
            runningApp.processIdentifier
        }

        /// A Boolean value indicating whether the app's extras menu
        /// bar has been successfully created and stored.
        var hasExtrasMenuBar: Bool {
            extrasMenuBar != nil
        }

        /// A Boolean value indicating whether the app is in a valid
        /// state for making accessibility calls.
        var isValidForAccessibility: Bool {
            // These checks help prevent blocking that can occur when
            // calling AX APIs while the app is an invalid state.
            runningApp.isFinishedLaunching &&
            !runningApp.isTerminated &&
            runningApp.activationPolicy != .prohibited &&
            !Bridging.isProcessUnresponsive(processIdentifier)
        }

        /// Creates a `CachedApplication` instance with the given running
        /// application.
        init(_ runningApp: NSRunningApplication) {
            self.runningApp = runningApp
        }

        /// Returns the accessibility element representing the app's extras
        /// menu bar, creating it if necessary.
        ///
        /// When the element is first created, it gets stored for efficient
        /// access on subsequent calls.
        func getOrCreateExtrasMenuBar() -> UIElement? {
            if let extrasMenuBar {
                return extrasMenuBar
            }
            guard
                isValidForAccessibility,
                let app = AXHelpers.application(for: runningApp),
                let bar = AXHelpers.extrasMenuBar(for: app)
            else {
                return nil
            }
            extrasMenuBar = bar
            return bar
        }
    }

    /// State for the cache.
    private struct State {
        /// Minimum time that must pass before retrying a failed source-PID lookup.
        static let failedLookupTTL: TimeInterval = 30

        var apps = [CachedApplication]()
        var pids = [CGWindowID: pid_t]()
        var failedLookups = [CGWindowID: Date]()
    }

    /// The shared cache.
    static let shared = SourcePIDCache()

    /// The cache's protected state.
    private let state = OSAllocatedUnfairLock(initialState: State())

    /// Serializes slow source-PID lookups so that blocking Accessibility work
    /// and `CachedApplication` mutation never run concurrently, while leaving
    /// the state lock free for cached reads and the running-apps observer.
    private let lookupLock = NSLock()

    /// Observer for running applications.
    private lazy var cancellable = NSWorkspace.shared.publisher(for: \.runningApplications).sink { [weak self] runningApps in
        guard let self else {
            return
        }

        Logger.default.debug("Received new running applications")

        let windowIDs = Bridging.getMenuBarWindowList(option: .itemsOnly)

        state.withLock { state in
            // Convert the cached state to dictionaries keyed by pid to
            // allow for efficient repeated access.
            let appMappings = state.apps.reduce(into: [:]) { result, app in
                result[app.processIdentifier] = app
            }
            let pidMappings: [pid_t: [CGWindowID: pid_t]] = windowIDs.reduce(into: [:]) { result, windowID in
                if let pid = state.pids[windowID] {
                    result[pid, default: [:]][windowID] = pid
                }
            }

            // Create a new state that matches the current running apps.
            state = runningApps.reduce(into: State()) { result, app in
                let pid = app.processIdentifier

                if let app = appMappings[pid] {
                    // Prefer the cached app, as it may have already done
                    // the work to initialize its extras menu bar.
                    result.apps.append(app)
                } else {
                    // App wasn't in the cache, so it must be new.
                    result.apps.append(CachedApplication(app))
                }

                if let pids = pidMappings[pid] {
                    result.pids.merge(pids) { (_, new) in new }
                }
            }
        }
    }

    /// Creates the shared cache.
    private init() {
        Bridging.setProcessUnresponsiveTimeout(3)
    }

    /// Starts the observers for the cache.
    func start() {
        Logger.default.debug("Starting observers for source PID cache")
        _ = cancellable
    }

    /// Returns the cached process identifier for the given window,
    /// performing a lookup if needed.
    ///
    /// The fast path (a cached PID or an unexpired failed lookup) runs under
    /// the state lock only. The slow path performs blocking Accessibility and
    /// bounds-stabilization work *outside* the state lock — serialized by
    /// ``lookupLock`` — then commits the result back under the state lock.
    func pid(for window: WindowInfo) -> pid_t? {
        if case .resolved(let pid) = resolveFromState(window) {
            return pid
        }

        lookupLock.lock()
        defer { lookupLock.unlock() }

        // Another lookup may have resolved this window while we waited on the
        // lookup lock, so re-check the cached state before doing slow work.
        let apps: [CachedApplication]
        switch resolveFromState(window) {
        case .resolved(let pid):
            return pid
        case .needsLookup(let snapshot):
            apps = snapshot
        }

        // Blocking AX + Thread.sleep happen here, without holding the state lock.
        let outcome = SourcePIDCache.performLookup(for: window, apps: apps)

        return state.withLock { state in
            switch outcome {
            case .found(let pid):
                state.pids[window.windowID] = pid
                state.failedLookups.removeValue(forKey: window.windowID)
                return pid
            case .notFound:
                state.failedLookups[window.windowID] = Date()
                return nil
            case .indeterminate:
                return nil
            }
        }
    }

    /// Returns a decision for the given window from cached state without
    /// performing any blocking work. Holds the state lock only briefly.
    private func resolveFromState(_ window: WindowInfo) -> CachedDecision {
        state.withLock { state in
            if let pid = state.pids[window.windowID] {
                return .resolved(pid)
            }
            if let failedAt = state.failedLookups[window.windowID],
               Date().timeIntervalSince(failedAt) < State.failedLookupTTL {
                return .resolved(nil)
            }
            return .needsLookup(state.apps)
        }
    }
}

// MARK: - Lookup

private extension SourcePIDCache {
    /// The result of resolving a window from cached state.
    enum CachedDecision {
        /// The window's PID is known (or known-failed, represented as `nil`).
        case resolved(pid_t?)
        /// A slow lookup is required, carrying a snapshot of the cached apps.
        case needsLookup([CachedApplication])
    }

    /// The outcome of a slow source-PID lookup.
    enum LookupOutcome {
        /// A matching app was found.
        case found(pid_t)
        /// No matching app was found; the failure should be cached.
        case notFound
        /// The lookup could not be performed (not trusted, or the window's
        /// bounds never stabilized); no failure should be cached.
        case indeterminate
    }

    /// Performs the blocking Accessibility lookup for the given window against
    /// a snapshot of cached apps.
    ///
    /// This does not read or write shared cache state, so it is safe to call
    /// without holding the state lock. Concurrent calls are prevented by
    /// ``lookupLock``, so mutating each `CachedApplication`'s cached extras
    /// menu bar here remains free of data races.
    static func performLookup(for window: WindowInfo, apps: [CachedApplication]) -> LookupOutcome {
        guard
            AXHelpers.isProcessTrusted(),
            let windowBounds = stableBounds(for: window)
        else {
            return .indeterminate
        }

        for app in partitioned(apps) {
            guard let bar = app.getOrCreateExtrasMenuBar() else {
                continue
            }
            for child in AXHelpers.children(for: bar) {
                guard AXHelpers.isEnabled(child) else {
                    continue
                }
                guard
                    let childFrame = AXHelpers.frame(for: child),
                    framesMatch(childFrame, windowBounds)
                else {
                    continue
                }
                return .found(app.processIdentifier)
            }
        }

        return .notFound
    }

    /// Returns the given apps reordered so that those confirmed to have an
    /// extras menu bar come first, which speeds up the common case.
    static func partitioned(_ apps: [CachedApplication]) -> [CachedApplication] {
        var lhs = [CachedApplication]()
        var rhs = [CachedApplication]()
        for app in apps {
            if app.hasExtrasMenuBar {
                lhs.append(app)
            } else {
                rhs.append(app)
            }
        }
        return lhs + rhs
    }

    /// Returns the latest bounds of the given window after ensuring that the
    /// bounds are stable (a.k.a. not currently changing).
    ///
    /// This blocks until stable bounds can be determined, or until retrieving
    /// the bounds for the window fails.
    static func stableBounds(for window: WindowInfo) -> CGRect? {
        var cachedBounds = window.bounds

        for n in 1...5 {
            guard let currentBounds = window.currentBounds() else {
                // Failure here means the window probably doesn't exist anymore.
                return nil
            }
            if currentBounds == cachedBounds {
                return currentBounds
            }
            cachedBounds = currentBounds
            // Compute the sleep interval from the current attempt.
            Thread.sleep(forTimeInterval: TimeInterval(n) / 100)
        }

        return nil
    }

    /// Returns whether an accessibility menu extra frame matches a menu bar
    /// item window frame. AX and CGWindow frames can differ by a pixel or two
    /// while apps are finishing launch.
    static func framesMatch(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        lhs.center.distance(to: rhs.center) <= 2
    }
}
