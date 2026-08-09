# New menu bar items go to the visible section

**Date:** 2026-08-08
**Status:** Design, pending implementation

## Problem

macOS assigns every newly created status item the leftmost slot in the menu
bar. Ice's sections run left to right as:

```
[always-hidden items] ⟨AH control item⟩ [hidden items] ⟨H control item⟩ [visible items] … clock
```

so "leftmost" always falls past the always-hidden divider. Ice never
repositions the item, so the first time a user installs an app with a menu bar
extra, its icon is invisible and appears — to the user — not to have been
installed at all.

Ice should move a genuinely new item into the visible section instead.

## Scope

In scope:

- Detecting items Ice has never seen, persisted across launches.
- Moving those items into the visible section.

Out of scope:

- **Any user setting.** The destination is the visible section, always. An
  earlier draft had a picker over the three sections; it was cut. The default is
  right for essentially every user, and if the choice is ever wanted, it is a
  property, a defaults key, a picker and one `switch` on top of everything
  below — the detection machinery, which is the whole of the risk, is identical
  either way.
- Per-application rules.
- Any change to how existing, already-seen items are positioned.
- Multi-display correctness. `MenuBarItem.getMenuBarItems(on:option:)` returns
  items across *all* displays when no display is passed, which is how both the
  item cache and `applyLayoutProfile` read the menu bar today: the cache records
  the active display's identifier but never filters by it, and nothing
  correlates an item with the divider on its own display. Placement reads the
  menu bar exactly as `applyLayoutProfile` does and inherits that limitation
  unchanged. Filtering by display is not available here —
  `getMenuBarItemWindows(on:option:)` forces `.onScreen` when a display is
  passed, which drops every hidden and always-hidden item, i.e. the entire
  landing zone. Placement de-duplicates candidates by tag, so an item mirrored
  onto a second display is moved once.
- Running without Screen Recording permission: the feature is inert (§1).

## Design

### 1. The known-items registry

A new `Defaults.Key` case, `knownMenuBarItems = "KnownMenuBarItems"`, holds the
JSON-encoded set of `MenuBarItemTag`s Ice has ever seen on this Mac.
`MenuBarItemTag` is already `Codable` and `Hashable`. It is local state, not a
preference, so it goes under a new `// MARK: Local State` group in
`Defaults.Key` rather than with the settings.

An item is **new** when its tag is placeable (§2), absent from that set, and in
the landing zone (§3).

Four properties make this safe:

- **Key absent means first run.** When the key does not exist, Ice seeds it from
  the current layout and moves nothing. Existing users upgrading to this build
  therefore keep their arrangement untouched; only items that appear *after* the
  upgrade are placed. This is distinct from "the decoded set is empty", which is
  why the load path yields `Set<MenuBarItemTag>?` rather than defaulting to
  `[]`. A key that is present but fails to decode is logged at error level and
  treated as a first run — re-seeding is inert, whereas treating it as an empty
  set would rearrange the user's whole menu bar.
- **The set only grows.** Every pass unions the placeable tags it saw into the
  stored set; it never replaces it. A single pass sees only the active Space, so
  replacing would drop tags for items parked elsewhere and re-classify them as
  new when they come back.
- **It needs Screen Recording permission.** A tag is a namespace plus the item's
  window title, and the title comes from `kCGWindowName`, which is `nil` without
  that permission — `MenuBarItem` degrades it to `""`
  ([MenuBarItem.swift:327](../../../Ice/MenuBar/MenuBarItems/MenuBarItem.swift)),
  and some namespaces degrade to a per-launch UUID. Screen Recording is optional
  in Ice (`isRequired: false`,
  [Permission.swift:231](../../../Ice/Permissions/Permission.swift)), so Ice does
  run without it. Seeding from that state would record identities that change the
  moment the permission is granted, and the user's existing items would then look
  new and be moved. So: no permission, no seeding, no placement, and the key stays
  absent.
- **It is excluded from settings backups.** Add it to
  `SettingsBackup.excludedKeys`, alongside the existing deprecated and
  machine-specific keys. It is a record of what has appeared on *this* Mac, not
  a preference; carrying it to another machine would suppress placement there.
  The comment above `excludedKeys` gains this third category.

The load path reads `Defaults.object(forKey:)` and casts, rather than
`Defaults.data(forKey:)`, which returns `nil` for both an absent key and a
present value of the wrong type. A wrong-typed value is a corrupted registry, not
a fresh install, and is logged as such before being treated as a first run.

Unbounded growth is accepted: entries are a namespace plus a title, and the
realistic ceiling is tens of entries over the life of an install.

### 2. Placement eligibility

A tag is placeable when all of the following hold:

```swift
tag.isMovable && tag.canBeHidden && !tag.isControlItem
    && !tag.isSpacerItem && !tag.namespace.isUUID && !tag.title.isEmpty
```

This excludes items macOS pins in place (Clock, Control Center), items that
cannot be hidden at all, Ice's own control items and spacers, and anything whose
identity is not durable: a UUID namespace is minted per process launch and
cached by window ID
([MenuBarItem.swift:400](../../../Ice/MenuBar/MenuBarItems/MenuBarItem.swift)),
so the same item can be tagged differently after a relaunch — moving such an
item every launch is worse than leaving it alone. That test subsumes
`isSystemClone`, which is just the UUID namespace with a known title. The
empty-title test is the same reasoning for titles: an untitled item cannot be
told apart from its siblings in the same namespace.

Two distinct items sharing a namespace and title collapse to one entry in the
set, so the second is never recognised as new. That is a deliberate
false-negative: it leaves an item alone rather than moving the wrong one.

### 3. The placement pass

A new `// MARK: - New Item Placement` extension on `MenuBarItemManager`, with
one entry point:

```swift
func placeNewItemsIfNeeded() async
```

**Where it is called.** At the end of `cacheItemsRegardless(_:)`, **outside**
the `cacheActor.runCacheTask { … }` closure. Calling it inside would be a bug:
the pass re-caches at the end, and `runCacheTask` cancels the previous task
before starting a new one, so a nested `cacheItemsRegardless` would cancel the
very task it was called from.

The pass does **not** read `itemCache`. It performs its own
`MenuBarItem.getMenuBarItems` read, because it needs the hidden and
always-hidden control items and `ItemCache` deliberately discards them
(`CacheContext.isValidForCaching`). Being independent of the cache is what keeps
this simple: there is no question of whether the pass is acting on a cache some
other invocation produced, because it is not acting on a cache at all.
`cacheItemsRegardless` is merely the existing "something changed, re-examine the
menu bar" trigger — it already fires on app launch/quit, Space change, screen
parameter change, frontmost app change, and a 30 s fallback poll.

**When it defers.** One synchronous check on entry, with no `await` before it:

- `isPlacingNewItems` is already true. This is what terminates the recursion in
  step 6: the refresh re-enters `cacheItemsRegardless`, which calls this pass
  again, and the nested call returns at once. Set for the whole pass, cleared in
  a `defer`.
- Screen Recording permission is missing
  (`ScreenCapture.cachedCheckPermissions()`).
- `lastMoveOperationOccurred(within: .seconds(1))`. Every move by every workflow
  stamps `lastMoveOperationTimestamp` inside `postMoveEvents`
  ([MenuBarItemManager.swift:1120](../../../Ice/MenuBar/MenuBarItems/MenuBarItemManager.swift)),
  so this one existing signal covers `applyLayoutProfile`, `temporarilyShow`,
  `rehideTemporarilyShownItems`, `enforceControlItemOrder` and layout bar drags
  without any of them being modified. A menu bar that was being rearranged a
  moment ago is not one to read positions from. (A `move` that finds the item
  already correctly positioned returns before posting anything and so does not
  stamp — harmless, since nothing moved.)
- `temporarilyShownItemContexts` is non-empty — those items are parked in their
  shown positions, cached as if they were in their original ones, and the rehide
  will move them back to destinations computed before this pass.

**Deferring must not strand the item.** Nothing is recorded when the pass
defers, but that alone does not guarantee another pass. `cacheItemsRegardless`
records the current window-ID list *inside* `runCacheTask`, before placement runs
after it, and every routine trigger goes through `cacheItemsIfNeeded`, which
skips the re-cache entirely while those IDs match. A new item that arrives during
a temporary show, or within a second of any move, would therefore defer once and
then sit in the always-hidden section indefinitely — the 30 s fallback poll
included, because it too runs through `cacheItemsIfNeeded`.

So any path that returns with candidates unplaced — the two defer conditions
above, the failed-read returns in steps 1 and 2, and a candidate whose move
failed or could not be verified in step 4 — calls
`cacheActor.clearCachedItemWindowIDs()` on the way out, which forces the next
trigger to re-cache and re-run the pass. `uncheckedCacheItems` already uses this
exact mechanism for the same purpose ("Ensure next cache isn't skipped").

The clear must be the **last awaited operation** of the pass, after the step 6
refresh. A pass in which some candidates were placed and others were not does
both, and `refreshCacheAfterItemMoves()` runs `cacheItemsRegardless`, which writes
the window-ID list again — undoing an earlier clear. Its nested placement call
returns through the recursion guard without clearing, so the failed candidate
would be stranded by exactly the mechanism meant to rescue it.

Two paths deliberately do *not* clear. The `isPlacingNewItems` guard, because the
outer pass is still running and will do it. And the missing-permission gate,
because clearing there would force a full re-cache on every poll for as long as
permission is denied, which is indefinite.

That second carve-out needs its own trigger, because the grant itself changes
nothing the cache watches: if the window-ID list happens not to change afterwards,
the pass never runs again, and — worse, with the registry still absent — the next
app to launch becomes the seed, so that genuinely new icon is recorded as
pre-existing and never placed. `MenuBarItemManager.configureCancellables` gains a
sink on `appState.permissions.screenRecording.$hasPermission` that calls
`cacheItemsRegardless()` once on a false → true transition. This is the same shape
as the `settingsNavigationIdentifier` sink already there.

**Residual risk, accepted.** A workflow that starts *after* the entry check and
interleaves with the pass's own moves is not detected — once the pass starts
moving, its own moves stamp the same timestamp the entry check reads, so the
signal cannot distinguish them. Closing this would mean bracketing every existing
move workflow with a shared counter, i.e. modifying five working call sites to
serve one opt-in convenience — not a trade worth making.

What makes the residue tolerable is that interference is *detected after the
fact* rather than prevented: step 4 verifies each item's final position, so an
item that was knocked elsewhere is not recorded, and the pass clears the cached
window IDs so a later pass retries it. The user-visible failure is therefore a
delay, not a permanently mislaid icon.

The verification is per-item and immediate, so it cannot see interference that
arrives *after* that item's check — an item can be verified in place and then
dragged away a moment later, and it will already have been recorded. That case is
indistinguishable from the user simply moving an item afterwards, which is theirs
to do and which the feature must not undo.

**The pass:**

1. **Read the menu bar once, and order it explicitly.**
   `MenuBarItem.getMenuBarItems(option: .activeSpace)`, the same read
   `applyLayoutProfile` uses, then **sorted ascending by live `minX`**, read via
   `Bridging.getWindowBounds(for:)` with the item's stored `bounds` as a fallback.
   `MenuBarItem.bounds` is a snapshot taken when the window list was read and can
   be stale for off-screen windows — which is every item in the landing zone, the
   always-hidden section being off-screen by construction. A stale rectangle
   reorders the sort, and since the landing zone is the prefix before the leftmost
   control item, a bad order can put the divider in the wrong place and make items
   the user deliberately parked look like candidates.
   `CacheContext.bestBounds(for:)` makes the same correction on the caching path.
   Resolve it once per item, not inside the comparator. Return,
   recording nothing, if it contains no hidden control item — that is the "the
   read failed" signal `applyLayoutProfile` already treats as fatal, and it is
   the check that makes a degraded read inert instead of destructive.

   The sort is not redundant. `getMenuBarItems` returns
   `Bridging.getProcessMenuBarWindowList()` filtered and `.reversed()`, with no
   positional sort anywhere in the chain. That it comes out left to right is
   inferred only from the fact that `applyVisibleLayout` would otherwise rebuild
   saved profiles backwards. Every positional decision elsewhere in the manager is
   made from bounds, not array order — `CacheContext.findSection` compares `minX`
   and `maxX`, `enforceControlItemOrder` compares `hidden.bounds.maxX` against
   `alwaysHidden.bounds.minX`. Sorting here follows that idiom and removes the
   assumption rather than depending on it.
2. **Load the known set** (§1). On a first run — absent or undecodable key —
   seed from a second, unfiltered read, `MenuBarItem.getMenuBarItems(option: [])`,
   which drops the `.activeSpace` filter and so also sees items parked on other
   Spaces, record its placeable tags, and return without moving anything. That
   read is validated exactly as step 1's is: no hidden control item means it
   failed, so the pass logs and returns with the key still absent, and the next
   pass seeds again. Writing an unvalidated seed is the one way this design can
   damage an existing menu bar — a failed read stores a partial set, and the next
   pass, no longer a first run, finds the user's own always-hidden items
   unrecorded in the landing zone and moves them.
3. **Pick the candidates.** Because step 1 sorted by `minX`, the landing zone is
   simply the prefix of the read that precedes the leftmost control item — the
   always-hidden divider when that section is enabled, the hidden divider when it
   is not. (The sort is what makes "prefix" mean the same thing as
   `CacheContext.findSection`'s bounds comparison; without it, "prefix" would be
   an assumption about window-list order.) Within that prefix, walk left to right
   and collect placeable tags that are not in the known set, stopping at the first
   placeable tag that *is* known. Non-placeable tags are skipped without ending
   the walk; repeated tags are de-duplicated; each surviving tag maps back to the
   first item in the read that carries it.

   The positional test is what makes "new" mean *newly created* rather than
   merely *unrecorded*, and it is what lets the concurrency guard stay cheap. A
   single pass sees only the active Space, so an existing item first encountered
   on another Space is unrecorded too — but it is sitting where the user left it,
   not in the slot macOS hands to brand-new items, so the walk stops before it
   and it is recorded untouched.

   This is not airtight: an app that was installed before the upgrade but not
   running during seeding is absent from the seed, and if it later launches into
   the landing zone ahead of any known item, it is moved. It is a new item as far
   as Ice can tell, and the result — its icon becomes visible — is what the
   feature does anyway.
4. **Move.** Destination is the visible section: `.rightOfItem` the hidden
   control item, items in order, each chained off the previous one, so the first
   candidate ends up immediately right of the divider and they keep their
   relative order.

   The existing `applyVisibleLayout` cannot be reused: it is `throws` and aborts
   the remaining items on the first failure. Placement uses its own loop, which
   logs and swallows per-item errors like `enforceControlItemOrder` does,
   continues with the chain re-anchored on the last item that actually moved (the
   divider, if none did), and returns the tags it placed.

   A `move` that returns is not proof that the item arrived. `move` checks
   `itemHasCorrectPosition` *before* posting on each attempt, then returns as soon
   as `postMoveEvents` reports the item's origin changed — it never re-checks the
   destination
   ([MenuBarItemManager.swift:1220](../../../Ice/MenuBar/MenuBarItems/MenuBarItemManager.swift)).
   A drag that begins after `waitForUserToPauseInput` can satisfy that
   origin-changed wait while leaving the item somewhere else entirely. So the loop
   calls `itemHasCorrectPosition(item:for:)` itself after each `move` returns, and
   counts the item as placed only if it holds. It is `private nonisolated` and the
   new extension lives in the same file, so it is directly callable. The check has
   to happen immediately, before the chain advances, because each subsequent move
   shifts the bounds it reads.
5. **Record.** Union into the known set every placeable tag in the step 1 read,
   *minus* the candidates, *plus* the candidates verified as placed. A candidate
   whose move failed or could not be verified is **not** recorded — it is still in
   the landing zone, so the next pass finds it and retries; recording it would let
   one transient event failure permanently defeat the feature for that icon.

   Subtracting only the candidates, rather than recording only what lies outside
   the landing zone, is what stops a delayed false positive. An unknown item
   sitting *behind* the item that stopped the walk is neither placed nor a
   candidate; if it were left unrecorded, then the day the blocking item's app
   quits, the walk would run further, reach it, and drag an item the user had
   deliberately parked out of always-hidden. Recording it now means it is never a
   candidate again.
6. **Refresh.** If any candidate was verified as placed, call
   `refreshCacheAfterItemMoves()` so the layout bar reflects the new arrangement
   instead of waiting for the 30 s fallback poll.

### 4. Pure logic in its own file

`Ice/MenuBar/MenuBarItems/NewMenuBarItemPlacement.swift` holds the parts that
need no live menu bar:

```swift
enum NewMenuBarItemPlacement {
    static func isPlaceable(_ tag: MenuBarItemTag) -> Bool
    static func candidateTags(in orderedTags: [MenuBarItemTag], known: Set<MenuBarItemTag>) -> [MenuBarItemTag]
    static func tagsToRecord(
        seen orderedTags: [MenuBarItemTag],
        candidates: [MenuBarItemTag],
        placed: Set<MenuBarItemTag>
    ) -> Set<MenuBarItemTag>
    static func decodeKnownTags(from data: Data) -> Set<MenuBarItemTag>?
    static func encode(_ tags: Set<MenuBarItemTag>) -> Data?
}
```

The layer works on tags rather than items on purpose: `MenuBarItem`'s
initializers are private, so tests cannot build one, whereas
`MenuBarItemTag(namespace:title:)` is directly constructible. The manager maps
the returned tags back to items — deterministically, since candidates all precede
the first control item, so the first occurrence of a tag is the right one.
`candidateTags` implements the whole of step 3 — the control-item boundary, the
walk, the de-duplication — over the ordered tags of the read; `tagsToRecord`
implements step 5's rule, keeping the set algebra that a delayed false positive
turns on out of the manager and under test.

This mirrors how `MenuBarLayoutProfile` is factored away from
`MenuBarItemManager`, and is what makes the feature testable in `IceTests`,
which cannot drive real status items.

## Testing

`IceTests/NewMenuBarItemPlacementTests.swift`:

- the placeable predicate accepts an ordinary app item and rejects control
  items, spacers, immovable and non-hideable items, UUID-namespace tags
  (including the system clone), and empty-title tags;
- `candidateTags` bounds the walk at the leftmost control item, stops at the
  first known placeable tag, skips non-placeable tags without ending the walk,
  de-duplicates repeated tags, preserves input order, returns empty when every
  placeable tag is known, and returns empty when the input has no control item;
- `tagsToRecord` excludes every non-placeable tag and every unplaced candidate,
  includes the placed candidates, and — the case that matters — includes an
  unknown placeable tag that sits inside the landing zone *behind* the tag that
  stopped the walk, so it can never become a candidate on a later pass;
- first-run semantics: `decodeKnownTags` yields `nil` for an undecodable payload,
  distinguishable from a decoded empty set, and encode/decode round-trips. The
  absent-key and wrong-typed cases are decided by the manager's load path against
  `Defaults.object(forKey:)`, not by this helper, and are covered by the manual
  checks rather than unit tests.

`IceTests/SettingsBackupTests.swift`: extend the excluded-keys test to assert
`knownMenuBarItems` never enters a payload, and that applying a payload leaves a
value already stored under that key in the target untouched.

`IceTests` is a manually enumerated Xcode group — 31 explicit children in the
`PBXGroup` and a matching `Sources` build phase — so the new test file must be
added to `Ice.xcodeproj/project.pbxproj`, or it silently does not compile or run.

Not covered by automated tests: the move itself, and the manager-level
sequencing around it (the deferral checks, the window-ID clearing that guarantees
a retry, the post-move position verification, per-item failure continuation).
Repositioning needs granted screen-recording TCC, which a debug build cannot
inherit; injecting a fake mover to reach the rest would mean adding a test-only
seam to the class that performs the moves, while the decisions that loop
consumes — which items, in which order, towards which divider — are already pure
and covered above.

Live verification is manual, on a build with Screen Recording granted:

- upgrading with the key absent seeds and moves nothing — the existing
  arrangement is untouched;
- installing an app with a menu bar extra lands its icon immediately right of
  the hidden divider, and it stays there across a relaunch of both apps;
- launching two menu bar apps at once places both, in order;
- an item deliberately dragged back into always-hidden stays there — it is
  recorded, so it is never a candidate again;
- a new item appearing during a layout profile apply, a temporary show, or a
  layout bar drag is not moved during that workflow and **is** placed on a later
  pass, with the other workflow's result intact — specifically, an item that
  arrives while an item is temporarily shown still gets placed once the rehide
  completes and nothing else about the menu bar changes, which is the case the
  window-ID clearing exists for;
- an item dragged away by hand mid-placement is not recorded, and a later pass
  puts it where it belongs;
- with Screen Recording denied, nothing is seeded, recorded or moved — and
  granting it, without relaunching and without otherwise disturbing the menu bar,
  seeds immediately rather than waiting for the next app to launch.

## Files touched

| File | Change |
| --- | --- |
| `Ice/Utilities/Defaults.swift` | One new `Key` case in a new "Local State" group |
| `Ice/MenuBar/MenuBarItems/NewMenuBarItemPlacement.swift` | New — pure logic |
| `Ice/MenuBar/MenuBarItems/MenuBarItemManager.swift` | New extension; call site at the end of `cacheItemsRegardless`; permission-grant sink in `configureCancellables` |
| `Ice/Settings/Backup/SettingsBackup.swift` | Exclude `knownMenuBarItems` |
| `Ice.xcodeproj/project.pbxproj` | Register the new test file in the `IceTests` group and `Sources` phase |
| `IceTests/NewMenuBarItemPlacementTests.swift` | New — tests |
| `IceTests/SettingsBackupTests.swift` | Cover the new excluded key |
| `CHANGELOG.md` | Added entry |

No settings model, settings pane, or `SettingsView` change: there is no setting.
