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
                Two fixes to Settings ▸ About, both found by putting all five Dragon apps' \
                About panes side by side: the pane credited Ice as the project Ice 2 is based \
                on without linking to it anywhere, and it claimed two copyright holders where \
                the other apps name one. Nothing outside that pane changed.
                """,
            sections: [
                ChangeSection(kind: .fixed, entries: [
                    "Settings ▸ About now links the original project. The Credits section said \"Based on Ice by Jordan Baird\", but nothing in the pane pointed at Ice — you were told Ice 2 has an upstream and given no way to reach it. There is now an Original project row alongside Website and Support, opening github.com/jordanbaird/Ice. The credit line is unchanged; the same entry drives both, so the name and the link can no longer disagree.",
                ]),
                ChangeSection(kind: .changed, entries: [
                    // Deliberately does not reproduce the old two-holder line verbatim: the kit's
                    // conformance rule R14 counts the copyright symbol per line of Swift source,
                    // and it does not read string literals differently from the About slot itself.
                    "Settings ▸ About names one copyright holder. The line under the version used to carry two, Jordan Baird's for 2025 alongside Teddy Chan's for 2026; it now reads © 2026 Teddy Chan, matching every other Dragon app. Nothing about Ice 2's licensing or its origins changed: it is still GPL-3.0 inherited from Ice, the app's own copyright notice still names both authors, Jordan Baird is still credited in the pane — now twice, by the Original project link and the Based on line — and the full licence texts are still both bundled with the app and published at dragonapp.com/ice-2/licenses/.",
                ]),
            ]
        )
    }
}
