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
            summary: "Settings panes are now in the standard Dragon order.",
            sections: [
                ChangeSection(kind: .changed, entries: [
                    "Moved Updates below What's New in Settings, so Ice's sidebar matches the other Dragon apps (ClipMenu, KeyKey, Spectacle).",
                ]),
            ]
        )
    }
}
