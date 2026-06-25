# Ice 2 — Point update channels at your own infrastructure

**Date:** 2026-06-25
**Status:** Design approved (pending written-spec review)

## Problem

Ice 2 (`teddychan/ice-2`, a fork of `jordanbaird/Ice`) ships an update channel
that still points at the **previous author's** infrastructure. Two distinct
"data sources" are wrong:

1. **In-app updater (Sparkle).** `Ice/Resources/Info.plist` declares:
   - `SUFeedURL` = `https://jordanbaird.github.io/ice-releases/appcast.xml`
     — jordanbaird's feed, still live. Users clicking "Check for Updates" are
     offered *jordanbaird's* Ice, not this fork.
   - `SUPublicEDKey` = `3nfIGMOD8DALPE8vIdFo2tUOIVc2MVbzhc+2J9JLn+Q=`
     — jordanbaird's Sparkle signing key. We do not hold the matching private
     key, so we can never publish an update this app will accept.

2. **Homebrew cask** (`teddychan/homebrew-tap` → `Casks/ice-2.rb`) is broken on
   three counts:
   - `version "2.0.0"` — stale; latest release is **v2.0.1**.
   - `url` builds `Ice-v#{version}.zip`, but the actual release asset is named
     `Ice-2-v2.0.1.zip` — wrong filename pattern (would 404).
   - `app "Ice.app"` — the bundle inside the zip is actually named `Ice 2.app`.
   - No `livecheck`, so `brew` can't detect new versions.

There is **no appcast under our control yet**, so simply swapping the feed URL
would point the app at a 404.

## Verified facts (as of 2026-06-25)

- Existing release `v2.0.1` asset `Ice-2-v2.0.1.zip` contains `Ice 2.app`,
  which is **Developer ID signed** (`Developer ID Application: Lung Sang Chan
  (4AF3KGGV29)`), **notarized**, and **stapled** (`spctl` accepts it). The
  binary itself is update-ready; no rebuild is needed to fix the immediate
  problem.
- App bundle id: `com.jordanbaird.Ice` (kept — changing it would orphan user
  settings). XPC helper: `MenuBarItemService.xpc`
  (`com.jordanbaird.Ice.MenuBarItemService`), embedded at
  `Contents/XPCServices/`. Xcode scheme: `Ice`. Sparkle is an SPM dependency
  (2.8.0) embedded as `Sparkle.framework`.
- `teddychan/ice-2` has **no Actions secrets** configured. All signing/notary
  secrets currently live only on `clipmenu-2-premium`.

## Cross-app convention (the model to follow)

| App | Feed served from | Signing key | Release CI |
|---|---|---|---|
| clipmenu-2 | `www.dragonapp.com/appcast.xml` (CI target) | `p+F/ivF5…du8=` | `release.yml` (full) |
| yahoo-keykey-2 | `www.dragonapp.com/keykey/appcast.xml` | `p+F/ivF5…du8=` (same) | none (manual) |
| **ice-2 (this)** | **`www.dragonapp.com/ice-2/appcast.xml`** (new) | **`p+F/ivF5…du8=`** (adopt shared) | **port from ClipMenu** |

The established convention is: appcast at `www.dragonapp.com/<app>/appcast.xml`,
signed with one **shared** EdDSA key, binaries on each app's GitHub Releases.
KeyKey is the cleanest feed reference; ClipMenu is the cleanest CI reference.

> Note (out of scope, flag separately): ClipMenu's *Info.plist* still points at
> a dead `teddychan.github.io/ClipMenu-2/appcast.xml` (404) while its CI
> publishes to the live `www.dragonapp.com/appcast.xml`. ClipMenu's shipped app
> is therefore reading a 404 feed — a real latent bug in that app, to be fixed
> in its own repo.

## Locked decisions

- **Feed URL:** `https://www.dragonapp.com/ice-2/appcast.xml`, served from the
  `teddychan/www.dragonapp.com` repo at `docs/ice-2/appcast.xml` (Pages).
- **Signing key:** adopt the shared EdDSA key
  `p+F/ivF5bAYcmuNuCMNHcRv123A6LHFpCBagFm7Adu8=`. Private half already exists as
  the `SPARKLE_EDDSA_PRIVATE_KEY` secret. No new key.
- **Binary source:** `teddychan/ice-2` GitHub Releases (unchanged).
- **Cask:** `teddychan/homebrew-tap` → `Casks/ice-2.rb`.
- **Build automation:** Approach A — full CI on `teddychan/ice-2`, ported from
  ClipMenu's `release.yml`, adapted for Xcode.

## Part 1 — Immediate fix (correct on both channels today)

1. **`Ice/Resources/Info.plist`**
   - `SUFeedURL` → `https://www.dragonapp.com/ice-2/appcast.xml`
   - `SUPublicEDKey` → `p+F/ivF5bAYcmuNuCMNHcRv123A6LHFpCBagFm7Adu8=`

2. **Backfill appcast for v2.0.1** (one-time, makes existing/older installs
   updatable):
   - Run Sparkle's `generate_appcast` over the existing notarized
     `Ice-2-v2.0.1.zip` with the shared private key and
     `--download-url-prefix https://github.com/teddychan/ice-2/releases/download/v2.0.1/`.
   - Publish the resulting `appcast.xml` to the `www.dragonapp.com` repo at
     `docs/ice-2/appcast.xml`, commit, push `main` (Pages rebuilds). Touch only
     that file.

3. **Fix `Casks/ice-2.rb`** (in `teddychan/homebrew-tap`):
   - `version "2.0.1"`
   - `url "https://github.com/teddychan/ice-2/releases/download/v#{version}/Ice-2-v#{version}.zip"`
   - `sha256` = SHA-256 of `Ice-2-v2.0.1.zip`
     (`f12d73e0a382c8fde2751766e99fc327892a2dfd3437f8466a5bbe9280cb281d`)
   - `app "Ice 2.app"` (was `Ice.app`)
   - Add `livecheck` against `https://github.com/teddychan/ice-2/releases/latest`.
   - Keep `uninstall quit: "com.jordanbaird.Ice"` and the `zap` paths
     (verified bundle id).

## Part 2 — Release automation (Approach A: full CI)

Add `.github/workflows/release.yml` to `teddychan/ice-2`, ported from
ClipMenu's, adapted for an Xcode app. Trigger: push tag `v*` (+
`workflow_dispatch` for back-fill). Runner: `[self-hosted, macOS, ARM64]`.

Steps:
1. `xcodebuild archive -scheme Ice -project Ice.xcodeproj -configuration Release
   -archivePath …` then `xcodebuild -exportArchive` with an
   `exportOptions.plist` (`method: developer-id`). The archive/export embeds and
   signs `Sparkle.framework` (incl. its XPCServices / Autoupdate / Updater.app)
   and `MenuBarItemService.xpc` automatically with the Developer ID identity —
   no manual inside-out `codesign` like the ClipMenu swift-build path.
2. Import the Developer ID cert into an ephemeral keychain (reuse ClipMenu's
   keychain/cert-import step verbatim).
3. Notarize the exported `.app` (zip → `notarytool submit` → poll → staple →
   validate). Reuse ClipMenu's robust submit-once-and-poll logic.
4. Zip as `Ice-2-v#{version}.zip` (must match the cask URL and the existing
   asset naming) and `gh release upload` to the `teddychan/ice-2` release.
5. `generate_appcast` (from the resolved Sparkle SPM artifact) over the zip with
   `SPARKLE_EDDSA_PRIVATE_KEY` and `--download-url-prefix` = the ice-2 release
   asset URL; publish `appcast.xml` to `www.dragonapp.com` `docs/ice-2/`.
6. Bump `Casks/ice-2.rb` in `teddychan/homebrew-tap` (version + sha256), guarded
   by a live-URL check so the cask never points at a 404.

### Part 2 prerequisites (owner action — cannot be scripted here)

- Replicate these secrets from `clipmenu-2-premium` to `teddychan/ice-2`
  (same Apple team, so values are reusable):
  `DEVELOPER_ID_CERT_P12_BASE64`, `DEVELOPER_ID_CERT_PASSWORD`,
  `NOTARY_KEY_P8_BASE64`, `NOTARY_KEY_ID`, `NOTARY_ISSUER_ID`,
  `PUBLIC_RELEASE_TOKEN`, `SPARKLE_EDDSA_PRIVATE_KEY`.
  (`PROVISIONING_PROFILE_BASE64` / `APPLE_TEAM_ID` are iCloud-only and not
  needed for Ice.)
- Register a self-hosted macOS/ARM64 runner to `teddychan/ice-2`.
- The first tagged run validates the `xcodebuild` export-signing path — the one
  piece not verifiable without the runner + secrets.

## Components & boundaries

- **App update config** (`Info.plist`) — *what:* tells Sparkle where/how to
  check. *Depends on:* the appcast existing at the feed URL + the public key
  matching the private signing key.
- **Appcast publisher** (the `www.dragonapp.com` `docs/ice-2/appcast.xml` file,
  written by `generate_appcast`) — *what:* the signed manifest the app reads.
  *Depends on:* the release zip + private key.
- **Release workflow** (`release.yml`) — *what:* builds/signs/notarizes,
  produces the zip + appcast + cask bump on each tag. *Depends on:* secrets +
  runner.
- **Homebrew cask** (`Casks/ice-2.rb`) — *what:* the `brew` download source.
  *Depends on:* the release asset URL + sha256.

## Testing / verification

- **Part 1:**
  - `curl -I https://www.dragonapp.com/ice-2/appcast.xml` → 200; XML lists
    v2.0.1 with an `sparkle:edSignature` and the correct enclosure URL.
  - `plutil -p` the built app's Info.plist → new feed URL + shared key present.
  - `brew install --cask teddychan/tap/ice-2` (or `brew fetch`) resolves and
    downloads; `brew livecheck ice-2` reports 2.0.1.
  - Manual: a pre-2.0.1 build's "Check for Updates" now offers 2.0.1 from the
    dragonapp feed (not jordanbaird's).
- **Part 2:** push a throwaway tag (e.g. `v2.0.2-rc1`) → workflow builds, signs,
  notarizes, uploads, publishes appcast, bumps cask end-to-end; verify the
  notarized zip with `spctl -a -t install`.

## Out of scope

- A Dragon App studio marketing page for Ice 2 (only the appcast subfolder is
  required; a landing page + SEO is a separate task).
- Fixing ClipMenu's dead-feed Info.plist bug (separate repo/app — flag it).
- Changing the app bundle id away from `com.jordanbaird.Ice`.
