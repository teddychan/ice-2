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
/// This pane went four releases without an update — it still described 2.11.0 while 2.14.1
/// shipped — so 2.12.0 through 2.14.0 were never announced to anyone who reads the app rather
/// than the changelog, including the removal of item groups. The notes below are cumulative for
/// that reason, and each entry names the release it came from. `MAC-APP-RELEASE-LIFECYCLE.md`
/// now makes updating this file part of every public release, gated on the tag.
enum WhatsNewConfig {
    static var content: WhatsNewContent {
        WhatsNewContent(
            date: "2026-08-10",
            summary: """
                A maintenance release: nothing you can see behaves differently. Its fixes \
                all concern keeping a development build of Ice 2 separate from the copy you \
                have installed. These notes also catch up on 2.12.0 through 2.14.0, which \
                shipped without being announced here.
                """,
            sections: [
                ChangeSection(kind: .added, entries: [
                    "A newly installed app's menu bar icon now appears where you can see it (2.14.0). macOS hands every brand-new menu bar item the leftmost slot, which in Ice 2's layout sits inside the always-hidden section — so the first time you installed an app with a menu bar icon, that icon was invisible from the moment it was created, and the app looked like it had never added one. Ice 2 now recognises an item it has never seen before and moves it into the visible section. Items you have already arranged are left alone, and updating does not move anything: Ice 2 takes a note of everything currently in your menu bar first, so only icons that turn up afterwards count as new. If you then drag one into Hidden or Always-Hidden, it stays where you put it. This needs Screen Recording permission, which is what lets Ice 2 tell one menu bar item from another; without it, nothing is moved.",
                ]),
                ChangeSection(kind: .removed, entries: [
                    "Item groups are gone (2.12.0). The Groups section in Settings ▸ Layout — saving a set of hidden items under a name and revealing them with Show — has been removed, along with the option to point a trigger at a group. It saw very little use for the amount of the app it occupied, and layout profiles already cover arranging your menu bar. Any groups you had saved were deleted from your settings when you updated. Triggers still work: a trigger now always shows the hidden section when its app comes to the front, so the Target menu is gone. Existing hidden-section triggers are untouched; only a trigger that pointed at a group was dropped.",
                ]),
                ChangeSection(kind: .fixed, entries: [
                    "A future update can no longer wipe your settings (2.12.1). Ice 2 saves your preferences as a single encoded record. Because of a flaw in the shared Dragon framework, the next version that added a setting would have failed to read the record you already had, quietly fallen back to defaults, and then written those defaults over your real preferences the moment anything changed — every setting reset, with no warning and no way back. Nothing was lost: the flaw needed a future version to trigger it, and this closed it first.",
                    "Restoring a backup, or using either Relaunch Ice 2 button, brings Ice 2 back (2.12.0). Ice 2 asked macOS to reopen it before quitting, while it was still running — so macOS brought the running copy to the front, reported success, and the quit that followed left nothing running at all. Ice 2 disappeared and did not come back.",
                    "Restoring a damaged backup now refuses the file instead of erasing everything (2.12.1). Handing Settings ▸ Backup & Restore a corrupted backup cleared your entire settings store rather than declining to read it, so one bad file could take your working preferences with it.",
                    "The Layout pane keeps up with your menu bar again (2.12.0). Applying a layout profile rearranged the real menu bar immediately, but the Visible / Hidden / Always-Hidden bars in Settings could go on showing the old arrangement for up to half a minute. They now catch up about a second after the last item moves. The same staleness could affect the profile being applied: if you dragged an item and pressed Apply within a second of it, Ice 2 worked from the layout as it was before your drag and moved the wrong items.",
                    "Dragging an item between sections no longer freezes the section you took it from (2.12.0). Ice 2 pauses a section's bar while you drag out of it so it doesn't rearrange under your cursor, but it only unpaused the section you dropped into. Drag from Hidden to Visible and the Hidden bar stopped updating for good, so an item that had moved kept showing in both places — closing and reopening Settings was the only way out.",
                    "Menu bar item icons refresh while you are looking at them (2.12.0). Ice 2 only redraws its picture of your menu bar items while the pane that displays them is open, which is the Layout pane. Since 2.8.0 it had been checking for the Appearance pane instead — the one pane that shows no item icons — so the icons in the layout bars were whatever had been captured on some earlier visit, and a capture that failed kept showing a lettered placeholder.",
                    "A failed uninstall says so (2.12.1). If uninstalling Ice 2 hit a problem partway through, it quit reporting success anyway — after it had already torn your settings down.",
                    "VoiceOver can tell the menu bar shape buttons apart (2.12.1). In Settings ▸ Appearance, the buttons that choose how each end of the menu bar shape is drawn were pictures with no name attached, so picking a shape without looking at the screen meant guessing. They now read as \"Square cap\" and \"Round cap\". The tooltips you see on hover are unchanged.",
                    "Hardened the connection to Ice 2's bundled helper (2.12.1). Ice 2 asks a small helper process which app each menu bar item belongs to. When that connection was interrupted, the code that cleared it skipped the lock guarding every other use of it, so a cleanup and an in-flight request could overlap — a dropped request at best, a crash at worst. Every access now goes through the same lock.",
                ]),
                ChangeSection(kind: .changed, entries: [
                    "If you are coming from 2.9.x: uninstalling Ice 2 has moved into Settings. It used to be an Uninstall item in the Ice 2 menu that opened a separate window; since 2.10.0 it is the last pane in the Settings sidebar, with the confirmation right there in the pane. What gets removed is unchanged: the app and its login item, your settings, layout profiles, and hotkeys, and Ice 2's saved application state.",
                ]),
            ]
        )
    }
}
