//
//  MenuBarItemService.swift
//  Shared
//

import Foundation

enum MenuBarItemService {
    /// The suffix the XPC service's bundle identifier adds to its containing app's.
    private static let suffix = "MenuBarItemService"

    /// The identifier of the release app's XPC service — the fallback for a process that
    /// cannot state its own bundle id, and the value ``name`` derives in a release build.
    private static let releaseName = "com.dragonapp.ice.\(suffix)"

    /// The name the app connects to and the service listens on.
    ///
    /// Derived from the running bundle rather than hardcoded, because the Debug configuration
    /// builds the app as `com.dragonapp.ice.debug` while this constant named the release
    /// service outright. Both builds then asked launchd for the one name
    /// `com.dragonapp.ice.MenuBarItemService`, so an installed release and a local debug build
    /// could not be trusted to run side by side — the lifecycle spec's simultaneous-run
    /// requirement — and the debug app's embedded service wasn't even namespaced under its own
    /// app, which is what macOS expects of a bundled XPC service.
    ///
    /// This file compiles into *both* processes, and `Bundle.main` means different things in
    /// each: the app is `com.dragonapp.ice[.debug]`, the service is that plus `.\(suffix)`.
    /// Appending unconditionally would make the service listen on
    /// `…MenuBarItemService.MenuBarItemService` and never be reachable, so the suffix is added
    /// only when it isn't already there. One expression, two processes, no way for the client's
    /// name and the listener's name to drift apart.
    ///
    /// The value must stay equal to the XPC target's `PRODUCT_BUNDLE_IDENTIFIER` in
    /// `Ice.xcodeproj` (`com.dragonapp.ice.MenuBarItemService` in Release,
    /// `com.dragonapp.ice.debug.MenuBarItemService` in Debug) — that identifier is what launchd
    /// registers the embedded service under, and a bundled XPC service has no `MachServices`
    /// declaration of its own to state it a second time.
    static let name: String = {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return releaseName
        }
        return bundleID.hasSuffix(".\(suffix)") ? bundleID : "\(bundleID).\(suffix)"
    }()
}

extension MenuBarItemService {
    enum Request: Codable {
        case start
        case sourcePID(WindowInfo)
    }

    enum Response: Codable {
        case start
        case sourcePID(pid_t?)
    }
}
