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
            date: "2026-07-07",
            summary: "A fresh app icon — two ice cubes for Ice 2.",
            sections: [
                ChangeSection(kind: .changed, entries: [
                    "Refreshed the app icon: two ice cubes to represent Ice 2, keeping the familiar blue glass look.",
                ]),
            ]
        )
    }
}
