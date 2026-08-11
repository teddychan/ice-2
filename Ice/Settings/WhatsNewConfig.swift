//
//  WhatsNewConfig.swift
//  Ice
//

import DragonKit

/// App-owned "What's New" content for Ice 2, rendered by DragonKit's ``WhatsNewPane``.
///
/// Only the app's own content lives here — the layout is owned by DragonKit. The version is not
/// passed at all: ``WhatsNewContent`` reads `CFBundleShortVersionString` itself and renders it
/// through ``DragonVersion/display(_:)``, so it always matches About and the update checker and
/// carries the same single `v` prefix. Update the `date` and `sections` per release.
///
/// This pane once went four releases without an update — it still described 2.11.0 while 2.14.1
/// shipped — so 2.12.0 through 2.14.0 were never announced to anyone who reads the app rather
/// than the changelog, including the removal of item groups. 2.14.5 carried the cumulative
/// catch-up that paid that debt off, so these notes describe this release alone again.
/// `MAC-APP-RELEASE-LIFECYCLE.md` now makes updating this file part of every public release,
/// gated on the tag.
enum WhatsNewConfig {
    static var content: WhatsNewContent {
        WhatsNewContent(
            date: "2026-08-11",
            summary: """
                One fix, finishing what 2.14.6 started: the copyright notice macOS shows for \
                Ice 2 in Finder's Get Info panel now matches the one in Settings ▸ About. \
                Nothing about Ice 2's licensing or its origins changed.
                """,
            sections: [
                // 2.14.6's notes told users "the app's own copyright notice still names both
                // authors". That was true when written and is not any more, so this entry says so
                // outright rather than leaving the earlier claim to rot.
                //
                // Deliberately does not reproduce the old two-holder line verbatim: the kit's
                // conformance rule R14 counts the copyright symbol per line of Swift source, and
                // it does not read string literals differently from the About slot itself.
                ChangeSection(kind: .fixed, entries: [
                    "Finder's Get Info panel now shows the same copyright line as Settings ▸ About. It named two holders, Jordan Baird's for 2025 alongside Teddy Chan's for 2026, while About named one — so the app made two different claims about itself depending on where you looked. Both now read © 2026 Teddy Chan. 2.14.6's release notes said this notice still carried both authors, and that is what has changed here.",
                    "Nothing about Ice 2's licensing or its origins changed. It is still GPL-3.0, inherited from Ice. Jordan Baird's copyright notice is still in the LICENSE file that ships with the app and still in its bundled Acknowledgements, which is where the licence requires it. He is still credited twice in Settings ▸ About, by the Original project link and the Based on line, and the full licence texts are still published at dragonapp.com/ice-2/licenses/.",
                ]),
            ]
        )
    }
}
