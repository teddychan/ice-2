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
            date: "2026-07-09",
            summary: "Layout profile fix.",
            sections: [
                ChangeSection(kind: .fixed, entries: [
                    "\"Update\" on a saved layout profile now records your current arrangement. After dragging items between sections, Update could keep the old layout; Ice 2 now refreshes the menu bar before saving, so Update and Save Current Layout both store what's really in your menu bar.",
                ]),
            ]
        )
    }
}
