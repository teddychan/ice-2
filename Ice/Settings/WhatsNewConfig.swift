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
            date: "2026-08-04",
            summary: "Uninstalling Ice 2 has moved into Settings.",
            sections: [
                ChangeSection(kind: .changed, entries: [
                    "Removing Ice 2 used to be an Uninstall item in the Ice 2 menu that opened a separate window. It is now the last pane in the Settings sidebar, under Uninstall, and the confirmation appears right there in the pane. What gets removed is unchanged: the app and its login item, your settings, layout profiles, and hotkeys, and Ice 2's saved application state.",
                ]),
                ChangeSection(kind: .removed, entries: [
                    "The Uninstall item no longer appears in the Ice 2 menu. An unrecoverable action does not belong one click away from Quit in the everyday menu — Settings ▸ Uninstall is now the way to remove Ice 2 from inside the app.",
                ]),
                ChangeSection(kind: .fixed, entries: [
                    "Uninstalling no longer leaves an emptied settings file behind. macOS rewrites an app's preferences file as the app quits, which could recreate the file Ice 2 had just deleted. Ice 2 now deletes those leftovers again once it has quit.",
                ]),
            ]
        )
    }
}
