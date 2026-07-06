# Layout Pane Test Coverage — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an automated Swift Testing suite for the Layout pane's pure logic (menu-bar item tag classification, layout-profile & group serialization, settings-backup save/restore, section-name stability), plus a written manual test plan for the real menu-bar behavior that needs TCC permissions.

**Architecture:** A new `IceTests` unit-test target is added to `Ice.xcodeproj`, hosted by the `Ice` app so `@testable import Ice` can reach its `internal` types. A ~3-line guard in `AppDelegate` short-circuits app setup under tests so the host doesn't boot the real menu bar. Tests exercise only pure, permission-free code paths; everything requiring live `NSStatusItem`s / EventTaps / TCC is captured in a manual checklist doc.

**Tech Stack:** Swift Testing (`import Testing`, `@Test`, `#expect`), Xcode 26.6, macOS 26 deployment target, Swift 5.0, `xcodebuild test`. Target creation via the Ruby `xcodeproj` gem (with an Xcode-UI fallback, since only system Ruby 2.6 is present and the gem is not installed).

**Spec:** [docs/superpowers/specs/2026-07-06-layout-pane-tests-design.md](../specs/2026-07-06-layout-pane-tests-design.md)

---

## File Structure

Files created / modified across the plan:

- **Create** `scripts/add-icetests-target.rb` — idempotent Ruby script (uses the `xcodeproj` gem) that creates the `IceTests` target if missing, wires `TEST_HOST`/`BUNDLE_LOADER` to the `Ice` app, adds it to the shared `Ice` scheme's test action, and syncs every `IceTests/*.swift` file into the target. Re-run after adding each test file.
- **Modify** `Ice/Main/AppDelegate.swift` — add the `XCTestConfigurationFilePath` guard (the only production-code change).
- **Modify** `Ice.xcodeproj/project.pbxproj` + `Ice.xcodeproj/xcshareddata/xcschemes/Ice.xcscheme` — produced by the script; committed as generated output.
- **Create** `IceTests/SmokeTests.swift` — proves the target links and `@testable import Ice` resolves.
- **Create** `IceTests/MenuBarSectionNameTests.swift` — section-name order & raw-value stability.
- **Create** `IceTests/MenuBarItemTagTests.swift` — movability/hideability/control/spacer/bento/clone classification, `Namespace`, Codable, description.
- **Create** `IceTests/MenuBarLayoutProfileTests.swift` — profile & group accessors and Codable round-trip.
- **Create** `IceTests/SettingsBackupTests.swift` — payload round-trip, replace-not-merge, excluded keys, serialize/deserialize, schema/malformed rejection, list/prune, filename shape.
- **Create** `docs/testing/layout-pane-manual-tests.md` — the manual test plan.

**Note on Task 1:** creating the Xcode target is the one step that may require an install (`gem install`) or, if that fails, a human in Xcode. Every task after Task 1 is pure Swift + `xcodebuild` and is fully agent-automatable. Do Task 1 first and confirm the smoke test passes before proceeding.

---

## Task 1: Create the `IceTests` target + AppDelegate guard + smoke test

**Files:**
- Create: `IceTests/SmokeTests.swift`
- Create: `scripts/add-icetests-target.rb`
- Modify: `Ice/Main/AppDelegate.swift` (after the preview guard, ~line 39)
- Modify (generated): `Ice.xcodeproj/project.pbxproj`, `Ice.xcodeproj/xcshareddata/xcschemes/Ice.xcscheme`

- [ ] **Step 1: Write the smoke test file**

Create `IceTests/SmokeTests.swift`:

```swift
//
//  SmokeTests.swift
//  IceTests
//

import Testing
@testable import Ice

/// Proves the test target links against the Ice app host and that
/// `@testable import Ice` resolves the app's internal types.
struct SmokeTests {
    @Test func iceModuleIsImportable() {
        #expect(MenuBarSection.Name.allCases.count == 3)
    }
}
```

- [ ] **Step 2: Add the AppDelegate test guard**

In `Ice/Main/AppDelegate.swift`, inside `applicationDidFinishLaunching`, immediately AFTER the existing `#if DEBUG … XCODE_RUNNING_FOR_PREVIEWS … #endif` block and BEFORE the `switch appState.permissions.permissionsState` line, insert:

```swift
        // Don't perform setup when running unit tests. AppState is still
        // constructed eagerly (a read-only, non-prompting permission probe),
        // but this skips the heavy menu-bar wiring (status items, EventTaps,
        // timers) so the test host stays inert. Mirrors the preview guard above.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return
        }
```

- [ ] **Step 3: Write the target-creation script**

Create `scripts/add-icetests-target.rb`:

```ruby
#!/usr/bin/env ruby
# Idempotently add/refresh the IceTests unit-test target in Ice.xcodeproj.
# Requires the `xcodeproj` gem. Re-run after adding any IceTests/*.swift file.
require 'xcodeproj'

PROJECT = 'Ice.xcodeproj'
project = Xcodeproj::Project.open(PROJECT)

ice = project.targets.find { |t| t.name == 'Ice' }
abort 'Ice target not found' unless ice

test = project.targets.find { |t| t.name == 'IceTests' }
if test.nil?
  test = project.new_target(:unit_test_bundle, 'IceTests', :osx, '26.0')
  test.build_configurations.each do |config|
    s = config.build_settings
    s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.dragonapp.ice.IceTests'
    s['SWIFT_VERSION'] = '5.0'
    s['MACOSX_DEPLOYMENT_TARGET'] = '26.0'
    s['GENERATE_INFOPLIST_FILE'] = 'YES'
    s['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/Ice.app/Contents/MacOS/Ice'
    s['BUNDLE_LOADER'] = '$(TEST_HOST)'
    s['DEVELOPMENT_TEAM'] = 'K2ATHQPJDP'
    s['CODE_SIGN_STYLE'] = 'Automatic'
    s['SWIFT_EMIT_LOC_STRINGS'] = 'NO'
  end
  test.add_dependency(ice)

  # Register the target in the shared Ice scheme's Test action.
  scheme_dir = Xcodeproj::XCScheme.shared_data_dir(PROJECT)
  scheme_path = File.join(scheme_dir, 'Ice.xcscheme')
  scheme = Xcodeproj::XCScheme.new(scheme_path)
  ref = Xcodeproj::XCScheme::TestAction::TestableReference.new(test)
  scheme.test_action.add_testable(ref)
  scheme.save_as(PROJECT, 'Ice', true)
end

# Sync every IceTests/*.swift file into the target (add missing ones only).
group = project.main_group['IceTests'] || project.main_group.new_group('IceTests', 'IceTests')
already = test.source_build_phase.files_references.map { |r| r.real_path.to_s }
Dir.glob('IceTests/*.swift').sort.each do |path|
  abs = File.expand_path(path)
  next if already.include?(abs)
  file_ref = group.new_file(File.basename(path))
  test.add_file_references([file_ref])
end

project.save
puts "IceTests synced (#{test.source_build_phase.files.count} source files)"
```

- [ ] **Step 4: Install the gem and run the script**

Prefer a no-sudo user install (the gem is pure Ruby — no native build):

```bash
gem install --user-install xcodeproj
GEM_HOME="$(ruby -e 'puts Gem.user_dir')" ruby scripts/add-icetests-target.rb
```

Expected: `IceTests synced (1 source files)`.

If the user install fails on Ruby 2.6, try `sudo gem install xcodeproj` (pin an older release if the version resolver complains, e.g. `sudo gem install xcodeproj -v 1.24.0`), then re-run the `ruby scripts/add-icetests-target.rb` line.

**Fallback (only if the gem cannot be installed):** create the target manually in Xcode — File ▸ New ▸ Target ▸ *Unit Testing Bundle*, name `IceTests`, "Testing System" = Testing (Swift Testing), host application = `Ice`; add `IceTests/SmokeTests.swift` to it; then verify the `Ice` scheme's Test action lists `IceTests`. Commit the resulting `project.pbxproj`/scheme diff.

- [ ] **Step 5: Run the smoke test to verify the target works**

Run:

```bash
xcodebuild test -project Ice.xcodeproj -scheme Ice \
  -destination 'platform=macOS' -only-testing:IceTests 2>&1 | tail -30
```

Expected: build succeeds and `SmokeTests.iceModuleIsImportable` passes (`** TEST SUCCEEDED **`). If code-signing blocks the host launch, confirm automatic signing with team `K2ATHQPJDP` is available on this machine.

- [ ] **Step 6: Commit**

```bash
git add scripts/add-icetests-target.rb IceTests/SmokeTests.swift \
  Ice/Main/AppDelegate.swift Ice.xcodeproj
git commit -m "test(layout): add IceTests target, host guard, smoke test

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: `MenuBarSectionNameTests`

**Files:**
- Create: `IceTests/MenuBarSectionNameTests.swift`
- Under test: `Ice/MenuBar/MenuBarSection.swift` (`MenuBarSection.Name`)

- [ ] **Step 1: Write the failing test**

Create `IceTests/MenuBarSectionNameTests.swift`:

```swift
//
//  MenuBarSectionNameTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice

struct MenuBarSectionNameTests {
    // Profile snapshots iterate allCases in order; order is load-bearing.
    @Test func allCasesInDeclaredOrder() {
        #expect(MenuBarSection.Name.allCases == [.visible, .hidden, .alwaysHidden])
    }

    // Raw values must stay stable so profiles saved by older builds decode.
    @Test func rawValuesAreStable() throws {
        let data = try JSONEncoder().encode(
            [MenuBarSection.Name.visible, .hidden, .alwaysHidden]
        )
        let json = String(decoding: data, as: UTF8.self)
        #expect(json == #"["visible","hidden","alwaysHidden"]"#)
    }
}
```

- [ ] **Step 2: Add the file to the target and run**

```bash
GEM_HOME="$(ruby -e 'puts Gem.user_dir')" ruby scripts/add-icetests-target.rb
xcodebuild test -project Ice.xcodeproj -scheme Ice \
  -destination 'platform=macOS' -only-testing:IceTests/MenuBarSectionNameTests 2>&1 | tail -20
```

Expected: both tests PASS. (No implementation step — this exercises existing production code; the "failing" state would only appear if `Name` were reordered or its raw values changed.)

- [ ] **Step 3: Commit**

```bash
git add IceTests/MenuBarSectionNameTests.swift Ice.xcodeproj
git commit -m "test(layout): cover MenuBarSection.Name order and raw values

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: `MenuBarItemTagTests`

**Files:**
- Create: `IceTests/MenuBarItemTagTests.swift`
- Under test: `Ice/MenuBar/MenuBarItems/MenuBarItemTag.swift`

- [ ] **Step 1: Write the tests**

Create `IceTests/MenuBarItemTagTests.swift`:

```swift
//
//  MenuBarItemTagTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice

struct MenuBarItemTagTests {
    private func ordinary() -> MenuBarItemTag {
        MenuBarItemTag(namespace: .string("com.example.Widget"), title: "Widget")
    }

    @Test func ordinaryItemIsMovableHideableNonControlNonSpacer() {
        let tag = ordinary()
        #expect(tag.isMovable)
        #expect(tag.canBeHidden)
        #expect(!tag.isControlItem)
        #expect(!tag.isSpacerItem)
        #expect(!tag.isBentoBox)
        #expect(!tag.isSystemClone)
    }

    @Test func clockAndControlCenterAreImmovable() {
        #expect(!MenuBarItemTag.clock.isMovable)
        #expect(!MenuBarItemTag.controlCenter.isMovable)
    }

    @Test func nonHideableSystemItems() {
        #expect(!MenuBarItemTag.faceTime.canBeHidden)
        #expect(!MenuBarItemTag.audioVideoModule.canBeHidden)
        #expect(!MenuBarItemTag.screenCaptureUI.canBeHidden)
    }

    @Test func controlItemsAreRecognized() {
        #expect(MenuBarItemTag.visibleControlItem.isControlItem)
        #expect(MenuBarItemTag.hiddenControlItem.isControlItem)
        #expect(MenuBarItemTag.alwaysHiddenControlItem.isControlItem)
    }

    @Test func spacerItemIsRecognized() {
        // .ice namespace resolves to the host bundle id (com.dragonapp.ice)
        // under the Ice test host; prefix comes from MenuBarSpacer.
        let spacer = MenuBarItemTag(namespace: .ice, title: "Ice.Spacer.ABCDEF")
        #expect(spacer.isSpacerItem)
        #expect(!ordinary().isSpacerItem)
    }

    @Test func bentoBoxIsRecognized() {
        // MenuBarItemTag.controlCenter has title "BentoBox-0".
        #expect(MenuBarItemTag.controlCenter.isBentoBox)
    }

    @Test func systemCloneIsRecognized() {
        let clone = MenuBarItemTag(namespace: .uuid(UUID()), title: "System Status Item Clone")
        #expect(clone.isSystemClone)
    }

    @Test func namespaceOptionalMapsNilToNull() {
        #expect(MenuBarItemTag.Namespace.optional("x").isString)
        #expect(MenuBarItemTag.Namespace.optional(nil).isNull)
        #expect(!MenuBarItemTag.Namespace.optional("x").isNull)
    }

    @Test func codableRoundTripAcrossNamespaceKinds() throws {
        let tags = [
            ordinary(),
            MenuBarItemTag(namespace: .null, title: ""),
            MenuBarItemTag(namespace: .uuid(UUID()), title: "UUIDItem"),
        ]
        let data = try JSONEncoder().encode(tags)
        let decoded = try JSONDecoder().decode([MenuBarItemTag].self, from: data)
        #expect(decoded == tags)
    }

    @Test func descriptionFormatting() {
        #expect(ordinary().description == "com.example.Widget:Widget")
        #expect(MenuBarItemTag(namespace: .string("ns"), title: "").description == "ns")
    }
}
```

- [ ] **Step 2: Add to target and run**

```bash
GEM_HOME="$(ruby -e 'puts Gem.user_dir')" ruby scripts/add-icetests-target.rb
xcodebuild test -project Ice.xcodeproj -scheme Ice \
  -destination 'platform=macOS' -only-testing:IceTests/MenuBarItemTagTests 2>&1 | tail -20
```

Expected: all tests PASS.

- [ ] **Step 3: Commit**

```bash
git add IceTests/MenuBarItemTagTests.swift Ice.xcodeproj
git commit -m "test(layout): cover MenuBarItemTag classification and Codable

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: `MenuBarLayoutProfileTests`

**Files:**
- Create: `IceTests/MenuBarLayoutProfileTests.swift`
- Under test: `Ice/Settings/Models/MenuBarLayoutProfilesSettings.swift` (`MenuBarLayoutProfile`, `MenuBarItemGroup`)

- [ ] **Step 1: Write the tests**

Create `IceTests/MenuBarLayoutProfileTests.swift`:

```swift
//
//  MenuBarLayoutProfileTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice

struct MenuBarLayoutProfileTests {
    private func tag(_ title: String) -> MenuBarItemTag {
        MenuBarItemTag(namespace: .string("com.example"), title: title)
    }

    private func sampleProfile() -> MenuBarLayoutProfile {
        MenuBarLayoutProfile(
            id: UUID(),
            name: "Work",
            createdAt: Date(timeIntervalSince1970: 1000),
            updatedAt: Date(timeIntervalSince1970: 2000),
            sections: [
                .init(section: .visible, itemTags: [tag("A"), tag("B")]),
                .init(section: .hidden, itemTags: [tag("C")]),
                .init(section: .alwaysHidden, itemTags: []),
            ]
        )
    }

    @Test func itemTagsAndCountsPerSection() {
        let profile = sampleProfile()
        #expect(profile.itemTags(for: .visible) == [tag("A"), tag("B")])
        #expect(profile.itemCount(for: .visible) == 2)
        #expect(profile.itemTags(for: .hidden) == [tag("C")])
        #expect(profile.itemCount(for: .alwaysHidden) == 0)
    }

    @Test func missingSectionReturnsEmpty() {
        let profile = MenuBarLayoutProfile(
            id: UUID(), name: "Empty",
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            sections: []
        )
        #expect(profile.itemTags(for: .visible).isEmpty)
        #expect(profile.itemCount(for: .hidden) == 0)
    }

    @Test func profileCodableRoundTrip() throws {
        let profile = sampleProfile()
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(MenuBarLayoutProfile.self, from: data)
        #expect(decoded == profile)
    }

    @Test func groupCountAndCodableRoundTrip() throws {
        let group = MenuBarItemGroup(
            id: UUID(), name: "G",
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 2),
            itemTags: [tag("A"), tag("B")]
        )
        #expect(group.itemCount == 2)
        let data = try JSONEncoder().encode(group)
        let decoded = try JSONDecoder().decode(MenuBarItemGroup.self, from: data)
        #expect(decoded == group)
    }
}
```

- [ ] **Step 2: Add to target and run**

```bash
GEM_HOME="$(ruby -e 'puts Gem.user_dir')" ruby scripts/add-icetests-target.rb
xcodebuild test -project Ice.xcodeproj -scheme Ice \
  -destination 'platform=macOS' -only-testing:IceTests/MenuBarLayoutProfileTests 2>&1 | tail -20
```

Expected: all tests PASS.

- [ ] **Step 3: Commit**

```bash
git add IceTests/MenuBarLayoutProfileTests.swift Ice.xcodeproj
git commit -m "test(layout): cover layout profile & group accessors and Codable

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: `SettingsBackupTests`

**Files:**
- Create: `IceTests/SettingsBackupTests.swift`
- Under test: `Ice/Settings/Backup/SettingsBackup.swift`

- [ ] **Step 1: Write the tests**

Create `IceTests/SettingsBackupTests.swift`:

```swift
//
//  SettingsBackupTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice

struct SettingsBackupTests {
    /// A throwaway UserDefaults suite. Caller must clean it up (see `defer`).
    private func makeScratch() -> (defaults: UserDefaults, suite: String) {
        let suite = "IceTests." + UUID().uuidString
        return (UserDefaults(suiteName: suite)!, suite)
    }

    @Test func payloadRoundTripReproducesValues() {
        let (source, sSuite) = makeScratch()
        let (target, tSuite) = makeScratch()
        defer {
            UserDefaults.standard.removePersistentDomain(forName: sSuite)
            UserDefaults.standard.removePersistentDomain(forName: tSuite)
        }
        source.set("hello", forKey: Defaults.Key.iceIcon.rawValue)
        source.set(42, forKey: Defaults.Key.showOnHoverDelay.rawValue)

        let payload = SettingsBackup.makePayload(
            from: source, appVersion: "9.9", createdDate: Date(timeIntervalSince1970: 1000)
        )
        SettingsBackup.apply(payload, to: target)

        #expect(target.string(forKey: Defaults.Key.iceIcon.rawValue) == "hello")
        #expect(target.integer(forKey: Defaults.Key.showOnHoverDelay.rawValue) == 42)
    }

    @Test func applyIsReplaceNotMerge() {
        let (source, sSuite) = makeScratch()
        let (target, tSuite) = makeScratch()
        defer {
            UserDefaults.standard.removePersistentDomain(forName: sSuite)
            UserDefaults.standard.removePersistentDomain(forName: tSuite)
        }
        source.set("keep", forKey: Defaults.Key.iceIcon.rawValue)
        // A backed-up key present in target but absent from the payload must be removed.
        target.set(true, forKey: Defaults.Key.useIceBar.rawValue)

        let payload = SettingsBackup.makePayload(
            from: source, appVersion: "1", createdDate: Date(timeIntervalSince1970: 0)
        )
        SettingsBackup.apply(payload, to: target)

        #expect(target.string(forKey: Defaults.Key.iceIcon.rawValue) == "keep")
        #expect(target.object(forKey: Defaults.Key.useIceBar.rawValue) == nil)
    }

    @Test func excludedKeysNeverTravel() {
        let (source, sSuite) = makeScratch()
        defer { UserDefaults.standard.removePersistentDomain(forName: sSuite) }
        source.set("/tmp/x", forKey: Defaults.Key.backupFolderPath.rawValue)
        source.set(true, forKey: Defaults.Key.automaticBackupEnabled.rawValue)

        let payload = SettingsBackup.makePayload(
            from: source, appVersion: "1", createdDate: Date(timeIntervalSince1970: 0)
        )
        // PayloadKey is private -> inspect via the raw string key.
        let stored = payload["defaults"] as? [String: Any] ?? [:]
        #expect(stored[Defaults.Key.backupFolderPath.rawValue] == nil)
        #expect(stored[Defaults.Key.automaticBackupEnabled.rawValue] == nil)
    }

    @Test func serializeDeserializeRoundTrip() throws {
        let (source, sSuite) = makeScratch()
        defer { UserDefaults.standard.removePersistentDomain(forName: sSuite) }
        source.set("v", forKey: Defaults.Key.iceIcon.rawValue)

        let payload = SettingsBackup.makePayload(
            from: source, appVersion: "2.0", createdDate: Date(timeIntervalSince1970: 5)
        )
        let data = try SettingsBackup.serialize(payload)
        let back = try SettingsBackup.deserialize(data)

        #expect(SettingsBackup.appVersion(of: back) == "2.0")
        #expect(SettingsBackup.createdDate(of: back) == Date(timeIntervalSince1970: 5))
    }

    @Test func deserializeRejectsNewerSchema() throws {
        let payload: [String: Any] = [
            "schemaVersion": SettingsBackup.schemaVersion + 1,
            "defaults": [String: Any](),
        ]
        let data = try SettingsBackup.serialize(payload)
        #expect(throws: SettingsBackup.BackupError.unsupportedVersion(SettingsBackup.schemaVersion + 1)) {
            _ = try SettingsBackup.deserialize(data)
        }
    }

    @Test func deserializeRejectsValidNonDictionaryPlist() throws {
        // A VALID plist that is an array, not a dictionary — exercises the
        // `as? [String: Any]` guard (random bytes would fail parsing first).
        let data = try PropertyListSerialization.data(
            fromPropertyList: ["a", "b"], format: .binary, options: 0
        )
        #expect(throws: SettingsBackup.BackupError.malformed) {
            _ = try SettingsBackup.deserialize(data)
        }
    }

    @Test func fileNameShapeIsTimezoneRobust() {
        // timestamp() sets no timeZone, so only assert the SHAPE, not an
        // exact value from an absolute Date.
        let name = SettingsBackup.fileName(for: Date(timeIntervalSince1970: 0))
        let matched = name.range(
            of: #"^Ice-Settings-\d{4}-\d{2}-\d{2}-\d{6}\.icebackup$"#,
            options: .regularExpression
        )
        #expect(matched != nil)
    }

    @Test func listBackupsFiltersAndSortsNewestFirst() throws {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: "IceTests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        for stamp in ["2026-01-01-000000", "2026-01-02-000000", "2026-01-03-000000"] {
            try Data("x".utf8).write(to: folder.appending(path: "Ice-Settings-\(stamp).icebackup"))
        }
        try Data("y".utf8).write(to: folder.appending(path: "notes.txt")) // must be ignored

        let list = SettingsBackup.listBackups(in: folder)
        #expect(list.count == 3)
        #expect(list.first?.lastPathComponent == "Ice-Settings-2026-01-03-000000.icebackup")
    }

    @Test func pruneKeepsNewest() throws {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: "IceTests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        for stamp in ["2026-01-01-000000", "2026-01-02-000000", "2026-01-03-000000"] {
            try Data("x".utf8).write(to: folder.appending(path: "Ice-Settings-\(stamp).icebackup"))
        }
        SettingsBackup.prune(in: folder, keeping: 1)

        let remaining = SettingsBackup.listBackups(in: folder)
        #expect(remaining.count == 1)
        #expect(remaining.first?.lastPathComponent == "Ice-Settings-2026-01-03-000000.icebackup")
    }
}
```

- [ ] **Step 2: Add to target and run**

```bash
GEM_HOME="$(ruby -e 'puts Gem.user_dir')" ruby scripts/add-icetests-target.rb
xcodebuild test -project Ice.xcodeproj -scheme Ice \
  -destination 'platform=macOS' -only-testing:IceTests/SettingsBackupTests 2>&1 | tail -25
```

Expected: all tests PASS.

- [ ] **Step 3: Commit**

```bash
git add IceTests/SettingsBackupTests.swift Ice.xcodeproj
git commit -m "test(backup): cover payload round-trip, replace semantics, retention

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: Manual test plan document

**Files:**
- Create: `docs/testing/layout-pane-manual-tests.md`

- [ ] **Step 1: Write the manual test plan**

Create `docs/testing/layout-pane-manual-tests.md` with exactly this content:

````markdown
# Layout Pane — Manual Test Plan

The Layout pane's on-screen behavior (moving items, showing/hiding sections,
applying profiles) is driven by real `NSStatusItem`s and the scromble EventTap
barrier, which need **granted TCC permissions** and therefore cannot be
covered by the automated `IceTests` suite. Run this checklist by hand.

## Preconditions

- [ ] Run a **TCC-permissioned build** — the release-identity build **or** the
      installed app — **not** the isolated `com.jordanbaird.Ice.debug` build
      (it cannot hold the grants).
- [ ] **Accessibility** and **Screen Recording** are granted to that build.
- [ ] Start from a known menu bar with at least two movable third-party items.
- [ ] Open **Settings ▸ Layout**.

## 1. Move items among sections

- [ ] Drag a third-party item from the **Visible** bar to the **Hidden** bar.
  - Expected (menu bar): the item disappears from the always-visible strip and
    only appears when the Hidden section is revealed.
  - Expected (Layout pane): the item now sits in the Hidden bar; Visible bar loses it.
- [ ] Reveal the Hidden section (click the hidden control item / Ice icon).
  - Expected (menu bar): the moved item becomes visible.
- [ ] Drag the item from **Hidden** to **Always-Hidden**.
  - Expected (menu bar): item hidden until the always-hidden section is revealed.
  - Expected (Layout pane): item now in the Always-Hidden bar.
- [ ] Drag it back to **Visible**.
  - Expected (menu bar): item returns to the always-visible strip.
  - Expected (Layout pane): item back in the Visible bar.
- [ ] Attempt to drag the **Clock** and **Control Center** items.
  - Expected: they cannot be moved (immovable).
- [ ] Attempt to move a non-hideable system item (e.g. FaceTime) into Hidden.
  - Expected: it refuses to hide.

## 2. Backup / Update / Apply profile

- [ ] With a known arrangement, enter a name and click **Save Current Layout**.
  - Expected (Layout pane): a profile row appears with per-section counts.
- [ ] Rearrange several items, then click **Apply** on the saved profile.
  - Expected (menu bar): items snap back to the saved arrangement.
  - Expected (Layout pane): the three bars match the saved profile.
- [ ] Rearrange again, then click **Update** on the profile.
  - Expected (Layout pane): the profile's counts update to the new arrangement.
- [ ] Disable the Always-Hidden section (Advanced settings), then **Apply** a
      profile that contains always-hidden items.
  - Expected: the Always-Hidden section auto-enables, then items place correctly.
- [ ] Full backup round-trip: export an `.icebackup`, change the layout,
      restore the file, relaunch.
  - Expected: the exact layout from the backup returns.

## 3. Other important cases

- [ ] **Item groups:** save a group of hidden items, click **Show**.
  - Expected (menu bar): grouped items appear briefly, then auto-rehide.
- [ ] **Spacers:** add a spacer and adjust its width slider.
  - Expected (menu bar): the gap between items changes live.
- [ ] Delete the spacer.
  - Expected (menu bar): the gap disappears.
- [ ] Save a profile/group while a spacer exists, then inspect the profile.
  - Expected: the spacer is **not** captured into the profile or group.
- [ ] **Relaunch persistence:** create a profile, quit Ice, relaunch.
  - Expected: the profile still lists with correct counts.
- [ ] **Empty-section edges:** apply a profile with an empty section; save a
      profile with nothing hidden.
  - Expected: no crash; bars reflect the empty sections.
- [ ] **Permission gating:** revoke Screen Recording in System Settings.
  - Expected (Layout pane): the pane disables with its explanation.
- [ ] Re-grant Screen Recording and return to the app.
  - Expected (Layout pane): the pane re-enables.
````

- [ ] **Step 2: Commit**

```bash
git add docs/testing/layout-pane-manual-tests.md
git commit -m "docs(testing): add Layout pane manual test plan

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 7: Full-suite verification

**Files:** none (verification only)

- [ ] **Step 1: Run the entire IceTests suite**

```bash
xcodebuild test -project Ice.xcodeproj -scheme Ice \
  -destination 'platform=macOS' -only-testing:IceTests 2>&1 | tail -40
```

Expected: `** TEST SUCCEEDED **` with all suites (`SmokeTests`, `MenuBarSectionNameTests`, `MenuBarItemTagTests`, `MenuBarLayoutProfileTests`, `SettingsBackupTests`) passing and zero failures.

- [ ] **Step 2: Confirm no production behavior changed**

Run:

```bash
git diff --stat main -- Ice/
```

Expected: the only non-test change under `Ice/` is the guard in `Ice/Main/AppDelegate.swift`.

---

## Self-Review (completed during planning)

**Spec coverage:**
- Automated target + host + guard → Task 1. ✅
- `MenuBarItemTagTests` (isMovable/canBeHidden/isControlItem/isSpacerItem/isBentoBox/isSystemClone, Namespace.optional, Codable, description) → Task 3. ✅
- `MenuBarLayoutProfileTests` (profile & group accessors, missing section, Codable) → Task 4. ✅
- `SettingsBackupTests` (payload round-trip, replace-not-merge, excluded keys, serialize/deserialize, unsupportedVersion, malformed via valid non-dict plist, list/prune, filename shape) → Task 5. ✅
- `MenuBarSectionNameTests` (order + raw-value stability) → Task 2. ✅
- Manual test plan (all three scenario groups) → Task 6. ✅
- Review fixes applied: `PayloadKey` accessed by string key; `.malformed` uses a valid non-dictionary plist; filename asserted by shape (timezone-robust); gem-not-installed handled with `--user-install` + Xcode-UI fallback; spacer-exclusion kept manual. ✅

**Placeholder scan:** none — every code/command step has concrete content.

**Type consistency:** `Defaults.Key` raw values, `MenuBarItemTag` initializer/statics, `MenuBarLayoutProfile`/`MenuBarItemGroup` fields, and `SettingsBackup` signatures all match the source read during planning.
