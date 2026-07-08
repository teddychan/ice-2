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
            date: "2026-07-08",
            summary: "A simpler, cleaner Settings window.",
            sections: [
                ChangeSection(kind: .changed, entries: [
                    "General settings are decluttered into clear sections — Show Hidden Items, Rehide, and Ice 2 Bar — so the options you use most are front and center.",
                    "Advanced extras now tuck away behind expandable rows: automatic Ice 2 Bar and menu bar item spacing stay out of the way until you need them.",
                    "The Settings sidebar groups What's New, Updates, and About together, separated from the functional panes above.",
                    "Removed a duplicate Permissions list from the Advanced pane — Permissions still has its own dedicated pane.",
                ]),
            ]
        )
    }
}
