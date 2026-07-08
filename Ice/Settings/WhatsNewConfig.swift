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
            summary: "Fewer, clearer options in General.",
            sections: [
                ChangeSection(kind: .changed, entries: [
                    "Simpler show options: the two separate hover settings are now a single \"Show on hover\" that reacts to both the menu bar and the Ice 2 icon, with one delay.",
                    "The menu bar icon chooser (icon, custom image, dynamic appearance) moved to the Appearance settings, alongside the other look-and-feel options. General keeps the simple \"Show Ice 2 icon\" switch.",
                ]),
            ]
        )
    }
}
