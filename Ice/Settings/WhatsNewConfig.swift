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
            date: "2026-08-18",
            summary: L("app.whatsNew.2_15_1.summary"),
            sections: [
                // The keys carry the version, so each release replaces them rather than editing
                // the previous release's text in place. That is what lets `whats_new_path` in
                // release.yml gate on a real diff in all seven .strings files: reusing a key would
                // leave those files untouched while the notes changed completely.
                //
                // One `.changed` section and nothing else, because that is what this release is:
                // the DragonKit pin moved 4.0.0 -> 4.1.0 and both bundles' Info.plist moved into
                // App/. Neither changes anything a user can see. 2.14.5 set the precedent for
                // saying that outright rather than dressing a pin bump up as a fix.
                ChangeSection(kind: .changed, entries: [
                    L("app.whatsNew.2_15_1.changed.dragonKit"),
                    L("app.whatsNew.2_15_1.changed.housekeeping"),
                ]),
            ]
        )
    }
}
