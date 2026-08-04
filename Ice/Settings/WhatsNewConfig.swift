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
            summary: "Update checks are quiet and considerate again.",
            sections: [
                ChangeSection(kind: .fixed, entries: [
                    "Scheduled update checks stop interrupting you. When Ice 2 checks for updates on its own schedule, it shows the update window quietly instead of pulling you out of what you were doing. Version 2.10.0 moved updates onto the shared Dragon app framework and lost that, so a background check could take over the screen unprompted.",
                    "Ice 2 tells you when a background check finds an update. The notification titled \"A new update is available\" is back. Because the update window deliberately does not steal focus, it can sit behind whatever you are working in — the notification is how you know it is there. It applies only if you have Automatically check for updates turned on, which is where macOS asks permission to show notifications; declining changes nothing about how updates work.",
                ]),
                ChangeSection(kind: .changed, entries: [
                    "If you are coming from 2.9.x: uninstalling Ice 2 has moved into Settings. It used to be an Uninstall item in the Ice 2 menu that opened a separate window; since 2.10.0 it is the last pane in the Settings sidebar, with the confirmation right there in the pane. What gets removed is unchanged: the app and its login item, your settings, layout profiles, and hotkeys, and Ice 2's saved application state. That flow was rewritten in 2.10.0 on top of the shared framework — the same steps, covered by automated tests, but it is a rewrite of a destructive, one-way path, so please report anything that misbehaves.",
                ]),
            ]
        )
    }
}
