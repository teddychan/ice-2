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
            date: "2026-07-11",
            summary: "A behind-the-scenes reliability release.",
            sections: [
                ChangeSection(kind: .improved, entries: [
                    "Nothing changes in how Ice 2 looks or works. Under the hood, we added a large automated test suite that continuously checks Ice 2's core logic — your settings, backup & restore, keyboard shortcuts, and saved menu bar layouts. It acts as a safety net that catches mistakes before an update ships, so future releases are much less likely to accidentally break something that already works.",
                ]),
            ]
        )
    }
}
