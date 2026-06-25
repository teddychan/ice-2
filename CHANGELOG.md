# Changelog

## 2.1.0 - 2026-06-25

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
