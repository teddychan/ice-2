# Layout Pane — Test Coverage Design

**Date:** 2026-07-06
**Status:** Approved (pending spec review)
**Scope:** Add tests that verify the Layout settings pane behaves correctly — both the pure logic (automated) and the real menu-bar behavior (manual).

## Problem

The Layout pane ([`Ice/Settings/SettingsPanes/MenuBarLayoutSettingsPane.swift`](../../../Ice/Settings/SettingsPanes/MenuBarLayoutSettingsPane.swift)) lets the user move menu-bar items between **Visible / Hidden / Always-Hidden** sections, save/apply/update **layout profiles**, save **item groups**, add **spacers**, and back up / restore all settings. Today there is **no test coverage at all** — no test target exists in `Ice.xcodeproj`.

We want confidence that:
1. Moving an item among Active / Hidden / Always-Hidden updates the macOS menu bar and the pane correctly.
2. Backup, Update, and Apply of a profile reflect in both the macOS menu bar and the Layout pane.
3. Other important flows (groups, spacers, relaunch persistence, permission gating) work.

## Constraint that shapes the whole design

The part the user cares most about — *"the real macOS menu bar updates and shows correctly"* — is driven by real `NSStatusItem`s plus the **scromble EventTap barrier** in [`MenuBarItemManager.swift`](../../../Ice/MenuBar/MenuBarItems/MenuBarItemManager.swift). That path is **not unit-testable**: it requires live menu-bar items and granted Screen Recording + Accessibility (TCC) permissions. The isolated debug build (`com.jordanbaird.Ice.debug`) cannot hold those grants.

Therefore the request splits into two deliverables that live in different worlds:
- **Automated tests** for the pure "brain" (serialization, classification, accessors) — CI-safe, no permissions.
- **A written manual test plan** for the on-screen menu-bar behavior — run by a human on a real, permissioned build.

## Decisions (locked)

| Decision | Choice |
|---|---|
| Test forms | Automated unit tests **+** written manual test plan (no in-app harness) |
| Framework | **Swift Testing** (`@Test` / `#expect`) |
| Refactoring appetite | **Minimal** — test what is already pure; do **not** restructure `MenuBarItemManager` or extract the profile-apply ordering out of the EventTap path |
| Production code change | One ~3-line guard in `AppDelegate` (approved) |

## A. Automated test target

### Target setup
- New **Swift Testing unit-test target `IceTests`** added to `Ice.xcodeproj`.
- **Hosted by the `Ice` app** (`TEST_HOST` = the built app), because `Ice` is an app target (not a framework) and the types under test are `internal` — `@testable import Ice` requires a host. Extracting a framework/SPM package is explicitly out of scope (violates "minimal refactoring").
- pbxproj is edited with the Ruby **`xcodeproj`** gem (deterministic) rather than by hand. **The gem is NOT installed on this machine** — `ruby -e 'require "xcodeproj"'` currently fails. The implementation checklist must therefore make this an explicit first step with a fallback path:
  1. Try `gem install xcodeproj` (may need `sudo`) or a `bundler` install, then run a small Ruby script that adds the target, build phase, and `TEST_HOST` / `BUNDLE_LOADER` settings.
  2. If the gem cannot be installed, fall back to creating the target through Xcode's UI (documented, manual) and commit the resulting `project.pbxproj` diff.
- A new scheme/test action (or the existing `Ice` scheme's Test action) runs `IceTests`.

### Production seam (the only prod change)
In [`Ice/Main/AppDelegate.swift`](../../../Ice/Main/AppDelegate.swift) `applicationDidFinishLaunching`, add an early return when running under tests, directly beside the existing `XCODE_RUNNING_FOR_PREVIEWS` preview guard:

```swift
// Don't perform setup when running unit tests.
if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
    return
}
```

**Scope of this guard (accurate):** `AppState` is created eagerly as a stored property of `AppDelegate` ([`AppDelegate.swift:12`](../../../Ice/Main/AppDelegate.swift)), and `IceApp` (`@main`) passes it into its scenes ([`IceApp.swift:13`](../../../Ice/Main/IceApp.swift)) — both happen *before* `applicationDidFinishLaunching`. `AppState()` constructs `AppPermissions`, whose `init()` performs a **read-only** Accessibility / Screen-Recording probe ([`AppPermissions.swift:56`](../../../Ice/Permissions/AppPermissions.swift)) and registers a couple of Combine / NotificationCenter observers.

So this guard prevents the heavy `performSetup` work — creating `NSStatusItem` control items, installing the scromble EventTaps, timers, and menu-bar wiring — but it does **not** prevent the eager `AppState` construction or its permission probe.

**Decision (accepted, keeps the seam minimal):** we accept the eager `AppState` construction. The permission probe is read-only and **non-prompting** (`AXIsProcessTrusted` / `CGPreflightScreenCaptureAccess`), so under the test host it simply returns `false` and does no harm; no status items or event taps are created. Widening the seam (e.g. lazy `AppState`, or a test-mode `AppState`) is deliberately *not* done — it would touch app startup and `IceApp` wiring, exceeding "minimal refactoring." This residual is documented rather than engineered away.

### Coverage (pure logic only)

All of the following are already pure/`internal` and need no refactoring:

**1. `MenuBarItemTagTests`** — the rules that decide whether/how an item can move between sections:
- `isMovable` — `false` for `clock` and `controlCenter` (and `siri` pre-macOS 26); `true` for an ordinary third-party tag.
- `canBeHidden` — `false` for non-hideable items (`audioVideoModule`, `faceTime`, `screenCaptureUI`) and the `AudioVideoModule` UUID case; `true` for a normal item.
- `isControlItem` — `true` for Ice's three control-item tags, `false` otherwise.
- `isSpacerItem` — `true` for the Ice spacer namespace + autosave prefix; excluded from profiles/groups.
- `isBentoBox`, `isSystemClone` — classification correctness.
- `Namespace.optional(_:)` — non-nil → `.string`, nil → `.null`; `isNull` / `isString` / `isUUID` flags.
- Codable round-trip of `MenuBarItemTag` and `Namespace` (null / string / uuid cases).
- `description` formatting (`namespace` and `namespace:title`).

**2. `MenuBarLayoutProfileTests`**:
- `MenuBarLayoutProfile` Codable round-trip (with `SectionSnapshot`s).
- `itemTags(for:)` returns the right section's tags; missing section → `[]`.
- `itemCount(for:)` matches tag count; missing section → `0`.
- `MenuBarItemGroup` Codable round-trip; `itemCount` == `itemTags.count`.

**3. `SettingsBackupTests`** (the save/backup half of scenario 2):
- `makePayload(from:)` includes only keys with stored values; stamps `schemaVersion` / `appVersion` / `createdDate`.
  - **`PayloadKey` is `private`** — tests must inspect payloads by their raw **string** keys (`"schemaVersion"`, `"appVersion"`, `"createdDate"`, `"defaults"`), not by referencing `PayloadKey`. Where possible, prefer the public accessors `createdDate(of:)` / `appVersion(of:)` instead of reaching into the dictionary.
- `makePayload → apply` round-trip on a scratch `UserDefaults(suiteName:)` reproduces the stored values.
- **Apply is replace, not merge:** a key present in `defaults` but absent from the payload is *removed* by `apply`.
- `excludedKeys` (e.g. `.sections`, `.backupFolderPath`) never appear in a payload.
- `serialize → deserialize` round-trip is loss-free (binary plist).
- `deserialize` throws `.unsupportedVersion` for a payload whose `schemaVersion` exceeds the current one.
- `deserialize` throws `.malformed` for a **valid non-dictionary plist** (e.g. `serialize` an array or a top-level string via `PropertyListSerialization`), *not* random bytes — random bytes would throw `PropertyListSerialization`'s own parse error before the `as? [String: Any]` guard is reached, so they would not exercise `.malformed`.
- `listBackups(in:)` returns only `.icebackup` files, newest-first.
- `prune(in:keeping:)` deletes only the oldest beyond the limit.
- `fileName(for:)` / `timestamp(_:)` — **timezone caveat:** `timestamp(_:)` sets the POSIX locale but **no `timeZone`** ([`SettingsBackup.swift:135`](../../../Ice/Settings/Backup/SettingsBackup.swift)), so a fixed absolute `Date` renders differently across local/CI timezones. Do **not** assert an exact string from an absolute `Date`. Instead: assert the **shape** via regex (`^Ice-Settings-\d{4}-\d{2}-\d{2}-\d{6}\.icebackup$`), and if an exact value is wanted, build the expected string with a `DateFormatter` in the **current** timezone. (Changing production to pin a timezone is out of scope for this test task.)

**4. `MenuBarSectionNameTests`**:
- `allCases` == `[.visible, .hidden, .alwaysHidden]` (order matters — profile snapshots iterate it).
- Raw values are the stable strings `"visible"` / `"hidden"` / `"alwaysHidden"` (profiles saved by older builds must still decode) — assert via Codable.

### Explicitly NOT automated (documented as manual)
- `MenuBarItemManager.move(...)`, `applyLayoutProfile(...)`, `scrombleEvent(...)` — need real EventTaps + TCC.
- `MenuBarSection.show()/hide()`, control-item positioning — need real `NSStatusItem`s.
- LayoutBar drag-and-drop — driven by AppKit drag delegation on the real window.
- `MenuBarLayoutProfilesSettings.applyProfile`/`temporarilyShowGroup` — call into `itemManager` (real menu bar).
- Spacer/control-item exclusion from profiles & groups — the filtering is inside `private` `makeProfile` / `uniqueItemTags` and needs a live `itemCache`; only the `isSpacerItem` / `isControlItem` primitives are unit-tested (suite 1).

## B. Manual test plan

New document: `docs/testing/layout-pane-manual-tests.md`.

**Preconditions block:** run the release-identity (or otherwise TCC-permissioned) build — **not** the isolated debug build — with Screen Recording + Accessibility granted; start from a known menu-bar arrangement.

**Format:** numbered steps, each with an explicit **Expected (menu bar)** and **Expected (Layout pane)** line, and a checkbox.

**Scenario groups:**

1. **Move among sections**
   - Drag a third-party item Visible→Hidden; expect it to leave the always-visible strip (revealed only when the Hidden section is shown) and the Hidden layout bar to gain it.
   - Hidden→Always-Hidden and the reverse path back to Visible.
   - Toggle the Hidden / Always-Hidden sections via their control items and confirm the moved item shows/hides on the real menu bar.
   - Negative cases the code enforces: Clock and Control Center cannot be dragged (`isMovable == false`); non-hideable items refuse to move into Hidden.

2. **Backup / Update / Apply profile**
   - Save current layout as a profile; rearrange items; **Apply** → menu bar and layout bars snap back to the saved arrangement.
   - **Update** an existing profile → re-snapshots the current layout (counts change in the profile row).
   - Apply a profile that contains Always-Hidden items while that section is disabled → the section auto-enables first (per `applyProfile`), then items place correctly.
   - Full settings backup: export `.icebackup`, change the layout, **restore**, relaunch → the exact layout returns (`SettingsBackup.restore`).

3. **Other important cases**
   - **Item groups:** save a group, "temporarily show" → the grouped hidden items appear briefly, then auto-rehide.
   - **Spacers:** add a spacer, adjust its width slider → visible gap changes on the menu bar; delete it → gap disappears; confirm spacers are **not** captured into profiles/groups. (This end-to-end exclusion stays **manual**: the filtering lives in the `private` methods `makeProfile` / `uniqueItemTags` at [`MenuBarLayoutProfilesSettings.swift:168`](../../../Ice/Settings/Models/MenuBarLayoutProfilesSettings.swift) and [`:230`](../../../Ice/Settings/Models/MenuBarLayoutProfilesSettings.swift), so it can't be reached without either running the app or adding a pure helper — the latter is out of scope. The underlying `MenuBarItemTag.isSpacerItem` classification *is* covered automatically in suite 1, so the manual check only needs to confirm the wiring.)
   - **Relaunch persistence:** create a profile, quit, relaunch → the profile still lists with correct counts.
   - **Empty-section edges:** apply a profile with an empty section; save a profile with nothing hidden.
   - **Permission gating:** revoke Screen Recording → the Layout pane disables with its explanation; re-grant → it re-enables.

## Success criteria

- `IceTests` target builds and all Swift Testing cases pass locally via `xcodebuild test`. Tests are CI-runnable: they rely only on read-only, non-prompting permission probes (no TCC grant required) and touch no `NSStatusItem`s or EventTaps.
- The four test suites cover every pure member listed in section A.
- The AppDelegate `XCTestConfigurationFilePath` guard is the only change to production code; the accepted eager-`AppState` residual is documented, not "fixed."
- Backup timestamp assertions are timezone-robust (shape via regex, or expected built in the current timezone) — no exact-string assertion from an absolute `Date`.
- `docs/testing/layout-pane-manual-tests.md` exists with runnable, unambiguous steps and expected results for all three scenario groups.
- No change to `MenuBarItemManager` / EventTap code.

## Out of scope

- In-app verification harness.
- Extracting profile-apply ordering into a pure, testable unit.
- Any framework/SPM extraction of the app target.
- UI/snapshot tests of the SwiftUI panes.
