//
//  WhatsNewConfig.swift
//  Ice
//

import DragonKit

/// App-owned "What's New" content for Ice 2, rendered by DragonKit's ``WhatsNewPane``.
///
/// Only the app's own content lives here — the layout is owned by DragonKit. The version is
/// single-sourced from the bundle (``Constants/versionString``, i.e. `CFBundleShortVersionString`)
/// so it always matches About and the update checker; update the `date` and `sections` per release.
enum WhatsNewConfig {
    static var content: WhatsNewContent {
        WhatsNewContent(
            version: Constants.versionString,
            date: "2026-07-10",
            summary: "Idle-power and layout-profile fixes.",
            sections: [
                ChangeSection(kind: .fixed, entries: [
                    "Updating a saved layout profile can no longer erase it. If capturing the current layout failed, Update could overwrite the profile with an empty layout; Ice 2 now ignores an empty capture and leaves your saved profile untouched.",
                ]),
                ChangeSection(kind: .improved, entries: [
                    "Lower idle CPU and energy use. The Ice 2 Bar no longer captures the screen every few seconds while it's hidden, and menu bar item names are now computed once instead of on every access.",
                ]),
            ]
        )
    }
}
