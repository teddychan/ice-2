# macOS 27 compatibility prototype

This is an isolated experiment, not a replacement backend for Ice 2. It does not
install or launch a new Ice build, migrate profiles, move icons, or write menu bar
preferences. The prototype app has its own bundle identifier.

## Run

From the repository root, in a logged-in GUI session:

```sh
# Open an interactive window with Hide Selected, Show All, and Quit.
bash scripts/run-macos27-prototype.sh

# Create an I27 status item, hide it briefly, invalidate the assertion, and
# verify that the original number of AX occurrences returns before removing it.
bash scripts/run-macos27-prototype.sh --self-test
```

Requires Xcode command-line tools and Accessibility permission for the launching
context. It checks permission without prompting and exits if unavailable. The
runner builds an ad-hoc-signed app in a unique `/tmp/ice2-macos27-prototype.*`
directory and prints its path. It does not change system permissions.

Default mode opens a test window and creates a disposable I27 icon; it hides
nothing until Hide Selected is clicked. Select I27 or a discovered third-party
app bundle. Show All releases this prototype's assertion; closing the window or
quitting does the same. The app list is a snapshot taken at launch. No layout or
profile changes are saved. Self-test allows the other running app bundles and
known system item IDs, excludes only the disposable prototype bundle, and
invalidates the assertion in a `finally` block. The activation wait is bounded,
including if the callback never arrives. **Some system extras can nevertheless
disappear during the test** because this private assessment API does not expose
an allowlist entry for every Control Center module. Do not run alongside another
app using assessment assertions. Output contains app names and menu bar labels;
review it before sharing.

## Observed on 2026-09-17

Environment: macOS 27.0 (26A428), Xcode 26.6, Ice 2 release 2.15.2 (1389).

* The existing `scripts/menubar-probe.swift` returned one main menu bar window,
  at layer 24, and **zero individual item windows**. This reproduces the legacy
  discovery failure before any new prototype code runs.
* `MenuBarClientCore` loaded, and the configuration initializer, activation, and
  invalidation selectors all existed on this build.
* Accessibility discovery returned 44 groups across two AX window entries. These
  are raw observations, not 44 unique icons or a verified mapping to displays.
* Adding the disposable icon produced 46 groups and two prototype occurrences.
* The native activation callback succeeded without an error. During the
  assertion, 42 groups remained and **both prototype occurrences disappeared**.
* Invalidating the assertion restored both prototype occurrences (46 groups).
  The prototype then removed its own status item and exited.
* Focus was also absent during the assertion and returned afterward. The native
  "Hide Menu Bar Items" control changed between snapshots. This demonstrates
  collateral behavior; preserving every native item has **not** been validated.

These are AX observations, not pixel-level verification. Group frames on this
build overlap and some copies use unexpected coordinates; frame intersection
must not be treated as reliable proof of physical visibility or display identity.

## Integration decision

Native discovery and reversible hiding are feasible on this build. Do **not**
replace the production backend with this probe: the old `MenuBarItem` model
requires real window IDs for capture, clicks, movement, and cache identity.
Inventing window IDs for AX groups would break those consumers.

A production macOS 27 backend still needs:

1. Stable identities independent of window IDs, plus explicit migration and
   ambiguity handling for existing saved profiles. Multiple icons belonging to
   the same app cannot be independently hidden using the bundle allowlist alone.
2. A policy for native system modules the assessment API hides as a side effect.
   Do not silently promise full visible/hidden/always-hidden parity.
3. Verified AX/display coordinates, moving and clicking, and ScreenCaptureKit
   previews in place of per-window image capture.
4. Assertion lifecycle tests for repeated toggles, sleep/wake, Spaces, app exits,
   new apps launching while hidden, and multiple physical displays.
5. Runtime capability checks and a clear unavailable state when private APIs
   change; retain the existing backend for earlier macOS versions.

The accompanying Ice Bar UI fix only stops reporting "Loading" after a completed
empty cache attempt and offers the existing retry action. It does not claim to
restore macOS 27 hiding.

Research reference: [Pelmet](https://github.com/fif7y/pelmet), particularly its
`MBAssessmentShim.m`, `ItemEnumerator.swift`, and `MenuBarPolicy.swift`. The prototype
uses the observed Apple runtime selectors, AX tree shape, and system enum values;
it does not import Pelmet as a dependency. The API is private and undocumented.
