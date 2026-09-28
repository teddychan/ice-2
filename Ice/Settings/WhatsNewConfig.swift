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
            date: "2026-09-28",
            summary: L("app.whatsNew.summary"),
            sections: [
                // The keys are stable across releases (app.whatsNew.summary, .fixed1, .changed1, …)
                // rather than version-namespaced: each release overwrites the same keys' text in all
                // seven .strings files instead of adding new ones and abandoning the last release's,
                // so nothing is left behind for `whats_new_path` in release.yml to gate on — it
                // diffs the text at these keys, not the key names themselves.
                //
                // A patch release with two macOS 27 fixes from issue #120, both visible to users:
                // collapsed Hidden and Always-Hidden dividers no longer leave a gap (#125), and the
                // Layout editor strings, which #117 shipped in English in six locales, are now
                // translated (#122). `changed1` is the visible side of #123: the four Settings
                // sliders are now system sliders, which look different. The Xcode 27 build fix
                // behind that change, the stricter locale specifier tests and the run-debug.sh
                // changes do not affect a shipped build, so they appear only in CHANGELOG.md.
                ChangeSection(kind: .fixed, entries: [
                    L("app.whatsNew.fixed1"),
                    L("app.whatsNew.fixed2"),
                ]),
                ChangeSection(kind: .changed, entries: [
                    L("app.whatsNew.changed1"),
                ]),
            ]
        )
    }
}
