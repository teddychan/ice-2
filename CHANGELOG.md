# Changelog

## Unreleased

### Tests

- **Expanded the unit-test suite for the pure-logic layer.** Added 63 new test cases (45 → 108 total) across 8 new files in the `IceTests` target, all passing:
  - `ModifiersTests` — symbolic string, NSEvent/CoreGraphics/Carbon flag conversions (round-trips), and `Codable`.
  - `KeyCodeTests` — raw values, custom symbol mappings, key-equivalent fallback, and `Codable`.
  - `KeyCombinationTests` — display value, `NSEvent` init, system-reserved lookup, equality, and the two-element `Codable` encoding (including the wrong-count decode error).
  - `HotkeyActionTests` — persisted raw-value strings, `allCases`, and `Codable` (guards against renames that would break saved hotkeys).
  - `PredicatesTests` — the throwing and non-throwing predicate factories.
  - `IceColorTests` — component-preserving `Codable` round-trip and the invalid-ICC decode error path.
  - `IceGradientTests` — color stops, alpha/location transforms, `NSGradient` conversion, interpolated/average color, and `Codable`.
  - `ExtensionsTests` — `clamped`, `removingDuplicates`, `CGColor.brightness`, and `EdgeInsets` helpers.
- **Coverage of the targeted logic types:** `Modifiers` 0→100%, `KeyCode` 0→95%, `KeyCombination` 0→92%, `IceGradient` 6→74%, `Predicates` 0→64%, `IceColor` 0→49%. The remaining uncovered lines in these files are system-coupled (SwiftUI view bodies, Carbon/TIS system calls) and are not unit-testable headlessly. Overall app-target line coverage moved from 5.4% to 7.4%; the bulk of the app is GUI/system integration that requires a live session with granted permissions.
- **Backup & restore and layout profiles.** Added 11 more test cases (108 → 119 total) covering the backup/restore file round-trip and the layout-profile model:
  - `SettingsBackupTests` — `writeBackup`→`restore` round-trip, malformed-file rejection, `performBackup` write-and-prune, and the folder/config helpers (`defaultFolder`, `configuredFolder`, `automaticBackupEnabled`, `currentAppVersion`). Raises `SettingsBackup` coverage 65→96%.
  - `MenuBarLayoutProfileTests` — `applyProfile`/`temporarilyShowGroup` guards when no `AppState` is present, and the `ApplyError` description.
- **Layout-movement note:** the profile/group *model* (capture, create, update, delete, section snapshots) is unit-tested, but the actual movement *engine* (`MenuBarItemManager`) drives real menu-bar items via synthesized CGEvents and Accessibility and can only be exercised by the manual test checklist, not units.
- **Appearance configs, settings enums, and misc utilities.** Added 30 more test cases (119 → 149 total) across 5 new files:
  - `AppearanceConfigTests` — `MenuBarEndCap`/`MenuBarShapeKind`/`MenuBarTintKind` metadata + `Codable`, and `MenuBarFullShapeInfo`/`MenuBarSplitShapeInfo` `hasRoundedShape`, defaults, and round-trips (→ 100%).
  - `SettingsEnumsTests` — `RehideStrategy`, `IceBarAutoEnableMode`, `IceBarLocation`, `SectionDividerStyle` raw values, `allCases`, ids, localized titles, and out-of-range `init?` (`IceBarLocation` → 100%).
  - `MenuBarTriggerTests` — `MenuBarTrigger.bundleIdentifier`/`matches`, action raw values, `Codable`, and `MenuBarTriggerTarget` equality.
  - `UtilityHelpersTests` — `withMutableCopy` (mutation + throwing), `LocalizedErrorWrapper` (both branches, → 100%), `SystemAppearance` titles (→ 51%).
  - `HotkeyTests` — `Hotkey` init, disabled-without-`AppState`, and `Equatable`/`Hashable` (→ 56%).
- Whole-app line coverage moved 7.4% → 8.2%; the ceiling remains the GUI/system layer, which needs a live session, not units.

## 2.9.8 - 2026-07-10

### Fixed

- **Updating a layout profile can no longer erase it.** If capturing the current menu bar layout failed — for example right after Ice 2 launched, or if Screen Recording permission had been revoked — clicking **Update** on a saved profile could overwrite it with an empty layout. Ice 2 now ignores an empty capture and leaves your saved profile untouched.

### Improved

- **Lower idle CPU and energy use.** The Ice 2 Bar no longer captures the screen every few seconds while it's hidden — it only refreshes its background color while actually visible — and menu bar item names are now computed once instead of on every access. This continues the idle-power work from 2.8.4–2.8.6.

## 2.9.7 - 2026-07-09

### Fixed

- **"Update" on a layout profile now saves your latest arrangement.** After dragging menu bar items between sections, clicking **Update** on a saved profile could record the previous layout instead of the current one, so the profile looked unchanged (deleting and re-saving worked around it). Ice 2 now refreshes the menu bar layout before capturing, so both **Update** and **Save Current Layout** always store what's actually in your menu bar.

## 2.9.6 - 2026-07-08

### Changed

- **Simpler show options.** The two separate hover settings in General ("Show on hover over empty menu bar" and "Show on hover over Ice 2 icon") are now a single **Show on hover** that reacts to both, with one shared delay. Your existing hover preference is preserved.
- **Icon chooser moved to Appearance.** The menu bar icon chooser — icon, custom image, and dynamic appearance — now lives in the **Appearance** pane alongside the other menu bar look-and-feel options. General keeps the simple **Show Ice 2 icon** switch.

## 2.9.5 - 2026-07-08

### Changed

- **Simpler, cleaner Settings.** The General pane is reorganized into clear sections (Show Hidden Items, Rehide, Ice 2 Bar) so the most-used options are front and center. Advanced extras — automatic Ice 2 Bar and menu bar item spacing — now sit behind expandable "Automatic Ice 2 Bar" and "Advanced" rows, out of the way until you need them.
- **Grouped sidebar.** The Settings sidebar now groups What's New, Updates, and About together, separated from the functional panes above.
- **Removed a duplicate.** The Advanced pane no longer repeats the Permissions list — Permissions still has its own dedicated pane.

## 2.9.4 - 2026-07-08

### Changed

- **Settings pane order.** Moved Updates below What's New so Ice's Settings sidebar follows the shared Dragon app order (General → the app's own panes → Permissions → Backup & Restore → What's New → Updates → About).

## 2.9.3 - 2026-07-07

### Changed

- **New app icon.** The Ice 2 icon now shows two ice cubes — a nod to "Ice 2" — while keeping the familiar blue tile and glass look.

## 2.9.2 - 2026-07-06

### Fixed

- **"Check for Updates" now finds new releases.** The build number is now derived from the git commit count each release, so Sparkle correctly detects newer versions (previous releases all shared the same build number, which made update checks report "up to date"). No functional changes otherwise — same as 2.9.1.

## 2.9.1 - 2026-07-06

### Changed

- **Clearer "up to date" update message.** The dialog shown when you check for updates and you're already on the latest version has been reworded for clarity.
- **Richer version in About.** The About pane now shows the version as `v<version> (<build>) · <UTC build time>`, so it's easier to tell exactly which build you're running.

## 2.9.0 - 2026-07-06

### Fixed

- **Fixed a crash on first launch.** Ice 2 could crash immediately on launch when Accessibility hadn't been granted yet (for example, right after a fresh install), because a permission check could retrigger itself in a tight loop. It now launches reliably and keeps checking for the permission in the background without recursing.

### Changed

- **Layout is now its own Settings tab.** The menu bar **Layout** editor moved out of the Appearance tab's Style/Layout switch into its own item in the Settings sidebar, right after Appearance — so you can jump straight to arranging your menu bar items.
- **Refined the Settings UI.** About, What's New, and Permissions now use Ice 2's shared design components for a consistent look, and the Settings sidebar text is sized correctly.

### Added

- **What's New tab.** A new Settings tab shows what changed in the current version.

## 2.8.6 - 2026-07-05

### Fixed

- **Even lower idle CPU.** The pop-out Menu Bar Appearance editor was being built at launch and kept alive off screen, where its form kept re-laying itself out every display cycle. It's now built only when you actually open it (and released when closed), removing the remaining background CPU cost measured after 2.8.5. The editor itself is unchanged — it just loads on demand.

## 2.8.5 - 2026-07-05

### Fixed

- **Much lower idle CPU/energy use.** Ice 2 was keeping its Settings and Permissions windows laid out in the background even when they were closed and off screen, which made the app continuously re-render and burn several percent CPU at idle (visible in Activity Monitor's Energy tab). These windows now render their contents only while actually visible, so a closed Settings window costs nothing. This is the main fix for the reported battery/power drain, and it builds on the 2.8.4 changes.

## 2.8.4 - 2026-07-05

### Fixed

- **Lower power use.** Ice 2 no longer wakes on every mouse movement when it doesn't need to. The mouse-tracking used for "show on hover" is now only active while a hover option is actually turned on, so with hover off the app stays idle as you move the pointer — noticeably reducing CPU and energy use in Activity Monitor.
- **Lower CPU when switching apps (with a custom menu bar appearance).** The overlay that redraws the menu bar used to keep polling the macOS Accessibility API every 50 ms for up to 10 seconds after each app switch whenever the menu size hadn't changed. It now polls quickly only briefly while the menu settles, then backs off, cutting a CPU/energy spike that happened every time you changed apps.

## 2.8.2 - 2026-06-30

### Changed

- **Refined the About and Uninstall screens.** About now leads with a **Website** link (dragonapp.com/ice-2) and a **Support on GitHub** link that goes straight to the issues page, plus creator and license rows. **Uninstall** is now a clear confirmation sheet that lists exactly what gets removed, with the destructive **Uninstall** button on the left and **Cancel** as the default.

## 2.6.0 - 2026-06-29

### Added

- **Back up & restore your settings.** A new **Backup & Restore** settings pane saves a snapshot of all your Ice 2 settings — layout profiles, item groups, spacers, triggers, hotkeys, and appearance — to a folder you choose. Ice 2 keeps the newest 10 backups, backs up automatically when you quit, and restores any backup in one click. Point the backup folder at Dropbox, iCloud Drive, or Google Drive to sync your settings across Macs or set up a new Mac.

## 2.5.3 - 2026-06-28

### Added

- New option to show hidden menu bar items by hovering over the Ice 2 icon. Turn it on under Settings → General → "Show on hover over Ice 2 icon" (off by default). Each hover option now has its own delay slider shown right beneath it.

### Changed

- The existing "Show on hover" option is now labelled "Show on hover over empty menu bar" to make clear it reacts to empty areas of the menu bar, and its delay slider moved from Advanced settings to sit directly beneath the option in General settings. The "Automatically rehide" options now sit in the same section as the show options.

## 2.5.2 - 2026-06-27

### Changed

- Maintenance release: the CI lint workflow now runs on the latest supported Node.js runtime (GitHub Actions `actions/checkout@v7`, Node 24) and lints with the current SwiftLint (0.65.0) via its official image, replacing an unmaintained 2021-era action. A couple of now-redundant SwiftLint directives were removed. No user-facing changes.

## 2.5.1 - 2026-06-27

### Changed

- The always-hidden menu bar section is now enabled by default. You can still turn it off under Settings → Advanced → Menu Bar Sections.

## 2.5.0 - 2026-06-27

This update makes Ice 2 an Apple Silicon–only app.

### Changed

- **Ice 2 now runs only on Apple Silicon Macs** (the M1, M2, M3, M4 chips and newer). Support for older Intel-based Macs has been removed. If your Mac was made in late 2020 or later, it almost certainly has an Apple Silicon chip and you're all set. (You can check under  → About This Mac — look for a "Chip" line that says "Apple M…".)
- The app is now built just for Apple Silicon, so the download is a bit smaller and runs natively on your Mac with no Intel compatibility layer.

### Note

- If you're on an older Intel Mac, please stay on version 2.4.1, which remains available and continues to work.

## 2.3.0 - 2026-06-26

This release focuses on stability fixes for Tahoe/macOS 26 and early macOS 27 behavior reported upstream in `jordanbaird/Ice`.

### Added

- Added menu bar layout profiles, item groups, spacer items, trigger-based item showing, and extra hotkey actions for section divider icons, auto rehide, and temporarily showing individual menu bar items.
- Added an Advanced setting to disable Ice 2 right-click context menus in the menu bar. References upstream issue #892 and upstream PR #893.
- Added an option to remove the background behind the menu bar while keeping menu bar content visible.

### Fixed

- Added resilient Menu Bar Layout rendering when screen capture or item image capture fails, including per-item fallback labels instead of blank bars. References upstream issues #951, #921, #918, #916, #913, #891, #846, #833, #818, #816, #773, #762.
- Fixed MenuBarItemService XPC startup for ad-hoc/local builds without an Apple Team Identifier, preventing Menu Bar Layout from spinning forever on empty item data. References upstream issues #744 and #891, and upstream PRs #950 and #953.
- Fixed duplicate or same-app menu bar items overwriting each other in caches by keying item images, search IDs, and temporary visibility contexts by window identity. References upstream issues #857 and #854.
- Hardened synthetic menu bar click/move event handling to avoid checked-continuation double-resume crashes and stuck cursor hiding. References upstream issues #947, #821, #810, #796, #786, #759, #757, #751.
- Increased move-operation timing tolerance and reduced tight polling for apps whose menu bar items respond slowly on Tahoe. References upstream issues #918 and #861.
- Improved Ice Bar behavior so it does not auto-hide while the pointer is moving from the menu bar into the Ice Bar, and added a short grace period for transient offscreen frame reports. References upstream issues #925, #914, #871, #813, #890, #888, #814 and upstream PR #911.
- Fixed multi-display and fullscreen screen selection by preferring the display under the pointer when appropriate, including cases where macOS no longer reports an active menu bar display. References upstream issues #955, #929, #899, #858, #829, #825, #824, #790 and upstream PRs #868 and #922.
- Fixed Ice Bar sizing and color sampling when the reused Ice Bar panel moves between displays with different scale factors. References upstream issue #955.
- Anchored menu bar appearance overlays to the actual WindowServer menu bar bounds instead of inferred screen geometry, improving vertical monitor placement. References upstream issue #780.
- Fixed Menu Bar Layout getting stuck indefinitely on "Loading menu bar items..." by tracking completed cache attempts and offering a retry state when no manageable items are found. References upstream issues #954, #846, #818.
- Improved permissions onboarding by adding direct Accessibility settings URLs, active-window permission refresh, and manual recheck behavior. References upstream issues #882, #770, #934.
- Avoided stealing focus back from System Settings after permissions that may require relaunch, and clarified relaunch guidance for screen recording on macOS 26. References upstream issues #770 and #934.
- Prevented repeated Sparkle update permission prompts by declining automatic update-check permission prompting. References upstream issues #937, #912, #837.
- Added a Menu Bar Layout recovery action to restore the Ice 2 control icon when it has been removed. References upstream issues #919 and #860.
- Fixed color picker usability by allowing the appearance editor and system color panel to activate normally. References upstream issue #763.
- Improved tint alpha handling for menu bar appearance shapes so split/full shapes are visible while no-shape tint remains subtle. References upstream issue #943.
- Kept Ice as an accessory/menu bar app at launch to avoid unwanted Dock activation. References upstream issues #808, #768, #906.
- Added README uninstall instructions for Homebrew, manual removal, and optional settings cleanup. References upstream issue #949.
- Improved Tahoe source PID matching and Control Center title fallback for menu bar item identity. References upstream issues #832, #878, #887, #806.
- Fixed hide-application-menus behavior so it can still run when Ice Bar is enabled. References upstream issue #879.
- Fixed Option-click behavior so the always-hidden section can still be shown when regular Show on Click is disabled, and control-item Option-click falls back to normal expansion when the always-hidden section is disabled. References upstream issues #634 and #595.
- Fixed Show on Scroll so discrete mouse-wheel events can toggle hidden menu bar items instead of only high-delta trackpad swipes. References upstream issue #717.
- Excluded Ice's own spacer items from layout profiles, item groups, and trigger-based showing, so applying a profile or trigger no longer moves or clicks the app's spacer status items.
- Fixed menu bar appearance overlay placement by converting the WindowServer menu bar bounds from CoreGraphics to AppKit coordinates, correcting the overlay's vertical position on non-primary displays.
- Added a tag-based fallback when rehiding temporarily shown items, so an item is still returned to its original location if its owning app recreates its status window while shown.
- Ensured default layout profile and item group names stay unique even after earlier profiles/groups are deleted.

### Known Limitations

- macOS 27 introduces deeper system menu bar hiding behavior. This release improves cache, layout, and empty-state handling for the related reports, but full visible/hidden/always-hidden parity on macOS 27 still requires runtime validation on affected hardware. References upstream issue #954.
