# Changelog

## 2.8.1 - 2026-06-30

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
