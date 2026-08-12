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
    @MainActor
    static var content: WhatsNewContent {
        WhatsNewContent(
            date: "2026-08-11",
            summary: L("app.whatsNew.2_14_7.summary"),
            sections: [
                // 2.14.6's notes told users "the app's own copyright notice still names both
                // authors". That was true when written and is not any more, so this entry says so
                // outright rather than leaving the earlier claim to rot.
                //
                // Deliberately does not reproduce the old two-holder line verbatim: the kit's
                // conformance rule R14 counts the copyright symbol per line of Swift source, and
                // it does not read string literals differently from the About slot itself.
                ChangeSection(kind: .fixed, entries: [
                    L("app.whatsNew.2_14_7.fixed.copyright"),
                    L("app.whatsNew.2_14_7.fixed.licensing"),
                ]),
            ]
        )
    }
}
