# Ice 2 Update-Source Fix — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make both Ice 2 update channels (in-app Sparkle + Homebrew) point at infrastructure the current author controls, and automate it for future releases.

**Architecture:** Part 1 corrects the live channels now — repoint the app's Sparkle feed/key, publish a signed appcast for the existing v2.0.1 to `www.dragonapp.com/ice-2/`, and fix the Homebrew cask. Part 2 adds an Xcode-based `release.yml` to `teddychan/ice-2` (ported from ClipMenu) so each `v*` tag rebuilds, signs, notarizes, and republishes both channels.

**Tech Stack:** Sparkle 2.8.0 (SPM-vendored), Apple `notarytool`/`codesign`, GitHub Actions (self-hosted macOS/ARM64), Homebrew cask, GitHub Pages on `teddychan/www.dragonapp.com`.

**Repos touched:**
- `teddychan/ice-2` (this worktree) — Info.plist, release.yml, this plan/spec
- `teddychan/www.dragonapp.com` (`~/git/www.dragonapp.com`) — `docs/ice-2/appcast.xml`
- `teddychan/homebrew-tap` (`~/git/homebrew-tap`) — `Casks/ice-2.rb`

**Shared constants used throughout:**
- Feed URL: `https://www.dragonapp.com/ice-2/appcast.xml`
- Sparkle public EdDSA key: `p+F/ivF5bAYcmuNuCMNHcRv123A6LHFpCBagFm7Adu8=`
- v2.0.1 asset: `https://github.com/teddychan/ice-2/releases/download/v2.0.1/Ice-2-v2.0.1.zip`
- v2.0.1 sha256: `f12d73e0a382c8fde2751766e99fc327892a2dfd3437f8466a5bbe9280cb281d`
- `generate_appcast` (already resolved): under `~/Library/Developer/Xcode/DerivedData/Ice-*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast` (re-resolve with the `find` in Task 2 in case the DerivedData hash changes)

---

## Task 1: Repoint the in-app Sparkle feed + key

**Files:**
- Modify: `Ice/Resources/Info.plist:5-8` (this worktree)

- [ ] **Step 1: Edit the feed URL and public key**

Replace the two `<string>` values so the file reads exactly:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SUFeedURL</key>
	<string>https://www.dragonapp.com/ice-2/appcast.xml</string>
	<key>SUPublicEDKey</key>
	<string>p+F/ivF5bAYcmuNuCMNHcRv123A6LHFpCBagFm7Adu8=</string>
</dict>
</plist>
```

- [ ] **Step 2: Verify the plist is valid and has the new values**

Run: `plutil -p Ice/Resources/Info.plist`
Expected: prints a dict with `SUFeedURL => "https://www.dragonapp.com/ice-2/appcast.xml"` and `SUPublicEDKey => "p+F/ivF5bAYcmuNuCMNHcRv123A6LHFpCBagFm7Adu8="`. No parse error.

- [ ] **Step 3: Confirm no other source file still references the old feed/key**

Run: `grep -rn "jordanbaird.github.io/ice-releases\|3nfIGMOD8DALPE8vIdFo2tUOIVc2MVbzhc" Ice/ Shared/ MenuBarItemService/ 2>/dev/null`
Expected: no matches.

- [ ] **Step 4: Commit**

```bash
git add Ice/Resources/Info.plist
git commit -m "Point Sparkle feed + key at dragonapp.com/ice-2

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Backfill the signed appcast for v2.0.1 → publish to dragonapp

This makes existing/older installs able to find v2.0.1 via the new feed. Done in the `~/git/www.dragonapp.com` checkout.

**Files:**
- Create: `~/git/www.dragonapp.com/docs/ice-2/appcast.xml`

- [ ] **Step 1: Stage the existing notarized zip in a scratch dir**

```bash
WORK="$(mktemp -d)"
curl -fsSL -o "$WORK/Ice-2-v2.0.1.zip" \
  "https://github.com/teddychan/ice-2/releases/download/v2.0.1/Ice-2-v2.0.1.zip"
echo "$WORK"
```

- [ ] **Step 2: Confirm the download matches the known sha256**

Run: `shasum -a 256 "$WORK/Ice-2-v2.0.1.zip"`
Expected: hash equals `f12d73e0a382c8fde2751766e99fc327892a2dfd3437f8466a5bbe9280cb281d`. If it differs, STOP — the release asset changed; do not proceed.

- [ ] **Step 3: Write the shared Sparkle private key to a temp file**

The private key is the `SPARKLE_EDDSA_PRIVATE_KEY` secret on `clipmenu-2-premium`. It is NOT stored in any local repo. Obtain it one of two ways:
- If the signing Mac has it in its login keychain (Sparkle stores it there when generated): skip the `--ed-key-file` flag below and pass nothing — `generate_appcast` reads the keychain automatically.
- Otherwise, paste the private key (base64, single line) into `"$WORK/sparkle_ed_key"`:
  ```bash
  printf '%s\n' '<PASTE_SPARKLE_EDDSA_PRIVATE_KEY>' > "$WORK/sparkle_ed_key"
  ```

- [ ] **Step 4: Generate the appcast**

```bash
GEN="$(find ~/Library/Developer/Xcode/DerivedData -path '*sparkle/Sparkle/bin/generate_appcast' -type f | head -1)"
echo "Using: $GEN"
# If using the keychain key, drop the --ed-key-file line.
"$GEN" --ed-key-file "$WORK/sparkle_ed_key" \
  --download-url-prefix "https://github.com/teddychan/ice-2/releases/download/v2.0.1/" \
  "$WORK"
```

- [ ] **Step 5: Verify the generated appcast**

Run: `cat "$WORK/appcast.xml"`
Expected: contains one `<item>` for version 2.0.1, an `<enclosure>` with
`url="https://github.com/teddychan/ice-2/releases/download/v2.0.1/Ice-2-v2.0.1.zip"`,
a non-empty `sparkle:edSignature="..."`, and a `length` equal to the zip's byte size.

- [ ] **Step 6: Place it in the dragonapp Pages source**

```bash
mkdir -p ~/git/www.dragonapp.com/docs/ice-2
cp "$WORK/appcast.xml" ~/git/www.dragonapp.com/docs/ice-2/appcast.xml
```

- [ ] **Step 7: Commit + push the dragonapp repo**

```bash
cd ~/git/www.dragonapp.com
git add docs/ice-2/appcast.xml
git commit -m "appcast: add Ice 2 feed (v2.0.1)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
git push origin main
```

- [ ] **Step 8: Verify the feed is live (after Pages rebuilds, ~1 min)**

Run: `curl -sL -o /dev/null -w '%{http_code}\n' https://www.dragonapp.com/ice-2/appcast.xml`
Expected: `200`. Then `curl -sL https://www.dragonapp.com/ice-2/appcast.xml | head -40` shows the v2.0.1 item.

---

## Task 3: Fix the Homebrew cask

**Files:**
- Modify: `~/git/homebrew-tap/Casks/ice-2.rb`

- [ ] **Step 1: Rewrite the cask**

Replace the entire file with:

```ruby
cask "ice-2" do
  version "2.0.1"
  sha256 "f12d73e0a382c8fde2751766e99fc327892a2dfd3437f8466a5bbe9280cb281d"

  url "https://github.com/teddychan/ice-2/releases/download/v#{version}/Ice-2-v#{version}.zip"
  name "Ice 2"
  desc "Menu bar manager"
  homepage "https://github.com/teddychan/ice-2"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "Ice 2.app"

  uninstall quit: "com.jordanbaird.Ice"

  zap trash: [
    "~/Library/Application Support/com.jordanbaird.Ice",
    "~/Library/Caches/com.jordanbaird.Ice",
    "~/Library/HTTPStorages/com.jordanbaird.Ice",
    "~/Library/Preferences/com.jordanbaird.Ice.plist",
    "~/Library/Saved Application State/com.jordanbaird.Ice.savedState",
  ]
end
```

- [ ] **Step 2: Verify the download URL resolves**

Run: `curl -sI -L -o /dev/null -w '%{http_code}\n' "https://github.com/teddychan/ice-2/releases/download/v2.0.1/Ice-2-v2.0.1.zip"`
Expected: `200`.

- [ ] **Step 3: Audit the cask if Homebrew is installed**

Run: `brew audit --cask --new ~/git/homebrew-tap/Casks/ice-2.rb 2>&1 | tail -20` (or `brew style` if `audit` is heavy)
Expected: no errors about `url`/`sha256`/`app`. (A network-dependent audit may warn if run offline — the URL check in Step 2 is the authoritative gate.)

- [ ] **Step 4: Commit + push the tap**

```bash
cd ~/git/homebrew-tap
git add Casks/ice-2.rb
git commit -m "ice-2 2.0.1: fix filename, app name, add livecheck

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
git push origin main
```

- [ ] **Step 5: End-to-end brew check (optional, if Homebrew present)**

Run: `brew update && brew livecheck teddychan/tap/ice-2`
Expected: reports current 2.0.1.

---

## Task 4: Add the release workflow to teddychan/ice-2

Ported from ClipMenu's `release.yml`, adapted for the Xcode app. Built in this worktree.

**Files:**
- Create: `.github/workflows/release.yml`
- Create: `.github/release/exportOptions.plist`

- [ ] **Step 1: Create the export options plist**

Create `.github/release/exportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>developer-id</string>
	<key>signingStyle</key>
	<string>manual</string>
	<key>teamID</key>
	<string>4AF3KGGV29</string>
</dict>
</plist>
```

- [ ] **Step 2: Create the workflow**

Create `.github/workflows/release.yml`:

```yaml
name: Release

# Build, sign (Developer ID + hardened runtime), notarize, staple, and publish
# Ice 2 whenever a v* tag is pushed. Also publishes the Sparkle appcast to the
# marketing site and bumps the Homebrew cask.
#
# Required repository secrets (Settings -> Secrets and variables -> Actions):
#   DEVELOPER_ID_CERT_P12_BASE64  base64 of the "Developer ID Application" .p12
#   DEVELOPER_ID_CERT_PASSWORD    password set when exporting the .p12
#   NOTARY_KEY_P8_BASE64          base64 of the App Store Connect API key (.p8)
#   NOTARY_KEY_ID                 the API key's Key ID
#   NOTARY_ISSUER_ID              the API key's Issuer ID
#   PUBLIC_RELEASE_TOKEN          PAT scoped to teddychan/www.dragonapp.com + homebrew-tap
#   SPARKLE_EDDSA_PRIVATE_KEY     the shared Sparkle EdDSA private key
on:
  push:
    tags:
      - 'v*'
  workflow_dispatch: {}

permissions:
  contents: write

jobs:
  build:
    runs-on: [self-hosted, macOS, ARM64]
    steps:
      - uses: actions/checkout@v4

      - name: Resolve version
        run: |
          set -euo pipefail
          TAG="${GITHUB_REF_NAME}"
          echo "TAG=${TAG}" >> "$GITHUB_ENV"
          echo "VERSION=${TAG#v}" >> "$GITHUB_ENV"

      - name: Import Developer ID certificate
        env:
          CERT_P12_BASE64: ${{ secrets.DEVELOPER_ID_CERT_P12_BASE64 }}
          CERT_PASSWORD: ${{ secrets.DEVELOPER_ID_CERT_PASSWORD }}
        run: |
          set -euo pipefail
          if [ -z "${CERT_P12_BASE64:-}" ]; then
            echo "::error::DEVELOPER_ID_CERT_P12_BASE64 secret is not set." >&2
            exit 1
          fi
          KEYCHAIN_PATH="$RUNNER_TEMP/app-signing.keychain-db"
          KEYCHAIN_PASSWORD="$(openssl rand -base64 24)"
          CERT_PATH="$RUNNER_TEMP/developer_id.p12"
          echo "$CERT_P12_BASE64" | base64 --decode > "$CERT_PATH"
          security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
          security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
          security import "$CERT_PATH" -P "$CERT_PASSWORD" -A -t cert -f pkcs12 \
            -k "$KEYCHAIN_PATH" -T /usr/bin/codesign
          for url in \
            https://www.apple.com/certificateauthority/DeveloperIDG2CA.cer \
            https://www.apple.com/certificateauthority/DeveloperIDCA.cer \
            https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer; do
            f="$RUNNER_TEMP/$(basename "$url")"
            curl -fsSL -o "$f" "$url" && security import "$f" -k "$KEYCHAIN_PATH" >/dev/null 2>&1 || true
          done
          security set-key-partition-list -S apple-tool:,apple:,codesign: \
            -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" >/dev/null
          security list-keychains -d user -s "$KEYCHAIN_PATH" \
            $(security list-keychains -d user | sed s/\"//g)
          IDENTITY="$(security find-identity -v -p codesigning "$KEYCHAIN_PATH" \
            | grep 'Developer ID Application' | head -1 | awk '{print $2}')"
          if [ -z "$IDENTITY" ]; then
            echo "::error::No 'Developer ID Application' identity found." >&2
            exit 1
          fi
          echo "SIGN_IDENTITY=$IDENTITY" >> "$GITHUB_ENV"
          echo "KEYCHAIN_PATH=$KEYCHAIN_PATH" >> "$GITHUB_ENV"

      - name: Archive + export (Developer ID)
        run: |
          set -euo pipefail
          ARCHIVE="$RUNNER_TEMP/Ice.xcarchive"
          EXPORT_DIR="$RUNNER_TEMP/export"
          xcodebuild archive \
            -project Ice.xcodeproj \
            -scheme Ice \
            -configuration Release \
            -archivePath "$ARCHIVE" \
            -derivedDataPath "$RUNNER_TEMP/dd" \
            OTHER_CODE_SIGN_FLAGS="--keychain $KEYCHAIN_PATH" \
            CODE_SIGN_IDENTITY="$SIGN_IDENTITY" \
            CODE_SIGN_STYLE=Manual \
            DEVELOPMENT_TEAM=4AF3KGGV29
          xcodebuild -exportArchive \
            -archivePath "$ARCHIVE" \
            -exportPath "$EXPORT_DIR" \
            -exportOptionsPlist .github/release/exportOptions.plist
          APP="$(find "$EXPORT_DIR" -maxdepth 1 -name '*.app' | head -1)"
          if [ -z "$APP" ]; then
            echo "::error::No .app produced by exportArchive." >&2
            exit 1
          fi
          echo "APP=$APP" >> "$GITHUB_ENV"
          echo "DD=$RUNNER_TEMP/dd" >> "$GITHUB_ENV"
          codesign --verify --strict --verbose=2 "$APP"

      - name: Notarize and staple
        env:
          NOTARY_KEY_P8_BASE64: ${{ secrets.NOTARY_KEY_P8_BASE64 }}
          NOTARY_KEY_ID: ${{ secrets.NOTARY_KEY_ID }}
          NOTARY_ISSUER_ID: ${{ secrets.NOTARY_ISSUER_ID }}
        run: |
          set -euo pipefail
          KEY_PATH="$RUNNER_TEMP/notary_key.p8"
          echo "$NOTARY_KEY_P8_BASE64" | base64 --decode > "$KEY_PATH"
          NOTARIZE_ZIP="$RUNNER_TEMP/notarize.zip"
          ditto -c -k --sequesterRsrc --keepParent "$APP" "$NOTARIZE_ZIP"
          CREDS=(--key "$KEY_PATH" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER_ID")
          SUBMIT_JSON="$RUNNER_TEMP/submit.json"
          xcrun notarytool submit "$NOTARIZE_ZIP" "${CREDS[@]}" --output-format json > "$SUBMIT_JSON"
          SUBMISSION_ID="$(plutil -extract id raw -o - "$SUBMIT_JSON")"
          echo "Notarization submission: $SUBMISSION_ID"
          DEADLINE=$(( SECONDS + 3600 )); STATUS="In Progress"
          while [ "$STATUS" = "In Progress" ]; do
            if [ "$SECONDS" -ge "$DEADLINE" ]; then
              echo "::error::Notarization timed out. Submission: $SUBMISSION_ID" >&2; exit 1
            fi
            sleep 30
            if xcrun notarytool info "$SUBMISSION_ID" "${CREDS[@]}" --output-format json > "$RUNNER_TEMP/info.json" 2>/dev/null; then
              STATUS="$(plutil -extract status raw -o - "$RUNNER_TEMP/info.json")"
              echo "Status: $STATUS"
            else
              echo "::warning::poll failed (transient); re-polling $SUBMISSION_ID"
            fi
          done
          if [ "$STATUS" != "Accepted" ]; then
            echo "::error::Notarization status: $STATUS" >&2
            xcrun notarytool log "$SUBMISSION_ID" "${CREDS[@]}" || true
            exit 1
          fi
          xcrun stapler staple "$APP"
          xcrun stapler validate "$APP"

      - name: Zip notarized app
        run: |
          set -euo pipefail
          ZIP="Ice-2-${TAG}.zip"
          ditto -c -k --sequesterRsrc --keepParent "$APP" "${GITHUB_WORKSPACE}/${ZIP}"
          echo "ZIP=${ZIP}" >> "$GITHUB_ENV"

      - name: Upload to release
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          set -euo pipefail
          gh release view "$TAG" --repo "$GITHUB_REPOSITORY" >/dev/null 2>&1 \
            || gh release create "$TAG" --repo "$GITHUB_REPOSITORY" --title "Ice 2 $TAG" --generate-notes
          gh release upload "$TAG" "$ZIP" --repo "$GITHUB_REPOSITORY" --clobber

      - name: Publish appcast (Sparkle auto-update)
        env:
          PUBLIC_RELEASE_TOKEN: ${{ secrets.PUBLIC_RELEASE_TOKEN }}
          SPARKLE_EDDSA_PRIVATE_KEY: ${{ secrets.SPARKLE_EDDSA_PRIVATE_KEY }}
        run: |
          set -euo pipefail
          SITE_REPO="teddychan/www.dragonapp.com"
          if [ -z "${PUBLIC_RELEASE_TOKEN:-}" ] || [ -z "${SPARKLE_EDDSA_PRIVATE_KEY:-}" ]; then
            echo "::warning::PUBLIC_RELEASE_TOKEN and/or SPARKLE_EDDSA_PRIVATE_KEY not set — skipping appcast."
            exit 0
          fi
          GEN="$(find "$DD/SourcePackages/artifacts" -path '*sparkle/Sparkle/bin/generate_appcast' -type f | head -1)"
          if [ -z "$GEN" ]; then
            echo "::error::generate_appcast not found under DerivedData SourcePackages." >&2
            exit 1
          fi
          WORK="$RUNNER_TEMP/appcast"; mkdir -p "$WORK"
          cp "$ZIP" "$WORK/"
          KEY_FILE="$RUNNER_TEMP/sparkle_ed_key"
          printf '%s\n' "$SPARKLE_EDDSA_PRIVATE_KEY" > "$KEY_FILE"
          "$GEN" --ed-key-file "$KEY_FILE" \
            --download-url-prefix "https://github.com/${GITHUB_REPOSITORY}/releases/download/${TAG}/" \
            "$WORK"
          PAGES="$RUNNER_TEMP/pages"
          REMOTE="https://x-access-token:${PUBLIC_RELEASE_TOKEN}@github.com/${SITE_REPO}.git"
          git clone --depth 1 "$REMOTE" "$PAGES"
          mkdir -p "$PAGES/docs/ice-2"
          cp "$WORK/appcast.xml" "$PAGES/docs/ice-2/appcast.xml"
          ( cd "$PAGES"
            git config user.name "Ice 2 Release Bot"
            git config user.email "release-bot@users.noreply.github.com"
            git add docs/ice-2/appcast.xml
            git commit -m "appcast: ice-2 ${TAG}" || { echo "appcast unchanged"; exit 0; }
            git push origin HEAD:main )
          echo "Published appcast → https://www.dragonapp.com/ice-2/appcast.xml"

      - name: Bump Homebrew cask
        env:
          PUBLIC_RELEASE_TOKEN: ${{ secrets.PUBLIC_RELEASE_TOKEN }}
        run: |
          set -euo pipefail
          TAP_REPO="teddychan/homebrew-tap"
          ASSET_URL="https://github.com/${GITHUB_REPOSITORY}/releases/download/${TAG}/${ZIP}"
          if [ -z "${PUBLIC_RELEASE_TOKEN:-}" ]; then
            echo "::warning::PUBLIC_RELEASE_TOKEN not set — skipping cask bump."; exit 0
          fi
          if [ "$(curl -sI -L -o /dev/null -w '%{http_code}' "$ASSET_URL")" != "200" ]; then
            echo "::warning::Public asset not live ($ASSET_URL) — skipping cask bump."; exit 0
          fi
          SHA="$(shasum -a 256 "${GITHUB_WORKSPACE}/${ZIP}" | awk '{print $1}')"
          TAP_DIR="$RUNNER_TEMP/homebrew-tap"
          REMOTE="https://x-access-token:${PUBLIC_RELEASE_TOKEN}@github.com/${TAP_REPO}.git"
          git clone --depth 1 "$REMOTE" "$TAP_DIR"
          CASK="$TAP_DIR/Casks/ice-2.rb"
          /usr/bin/sed -i '' -E \
            -e "s/^  version \".*\"/  version \"${VERSION}\"/" \
            -e "s/^  sha256 \".*\"/  sha256 \"${SHA}\"/" \
            "$CASK"
          ( cd "$TAP_DIR"
            git config user.name "Ice 2 Release Bot"
            git config user.email "release-bot@users.noreply.github.com"
            git add Casks/ice-2.rb
            git commit -m "ice-2 ${VERSION}" || { echo "cask unchanged"; exit 0; }
            git push origin HEAD:main )
          echo "Bumped Homebrew cask → ice-2 ${VERSION} (${SHA})"
```

- [ ] **Step 3: Lint the workflow YAML**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/release.yml')); print('yaml ok')"`
Expected: `yaml ok`.

- [ ] **Step 4: Validate the export options plist**

Run: `plutil -lint .github/release/exportOptions.plist`
Expected: `.github/release/exportOptions.plist: OK`.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/release.yml .github/release/exportOptions.plist
git commit -m "Add Developer ID release workflow (build, notarize, appcast, cask)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Document the release prerequisites for the owner

The workflow can't run green until the owner replicates secrets + registers a runner. Capture the exact steps so it's not lost.

**Files:**
- Create: `docs/RELEASING.md`

- [ ] **Step 1: Write the runbook**

Create `docs/RELEASING.md`:

```markdown
# Releasing Ice 2

Pushing a `vX.Y.Z` tag to `teddychan/ice-2` triggers
`.github/workflows/release.yml`, which builds, Developer ID-signs, notarizes,
and staples the app, uploads `Ice-2-vX.Y.Z.zip` to the GitHub Release,
publishes the signed Sparkle appcast to
`https://www.dragonapp.com/ice-2/appcast.xml`, and bumps the Homebrew cask
`teddychan/tap/ice-2`.

## One-time setup

### 1. Repository secrets (Settings → Secrets and variables → Actions)
Reuse the same values already on `clipmenu-2-premium` (same Apple Team
`4AF3KGGV29`):

- `DEVELOPER_ID_CERT_P12_BASE64`
- `DEVELOPER_ID_CERT_PASSWORD`
- `NOTARY_KEY_P8_BASE64`
- `NOTARY_KEY_ID`
- `NOTARY_ISSUER_ID`
- `PUBLIC_RELEASE_TOKEN` (PAT with write access to
  `teddychan/www.dragonapp.com` and `teddychan/homebrew-tap`)
- `SPARKLE_EDDSA_PRIVATE_KEY` (the shared EdDSA private key; its public half
  `p+F/ivF5bAYcmuNuCMNHcRv123A6LHFpCBagFm7Adu8=` is in `Ice/Resources/Info.plist`)

### 2. Self-hosted runner
Register a macOS/ARM64 self-hosted runner to this repo with Xcode 26 (macOS 26
SDK). The workflow targets `runs-on: [self-hosted, macOS, ARM64]`.

## Cutting a release
1. Bump `MARKETING_VERSION` in `Ice.xcodeproj` and commit.
2. `git tag vX.Y.Z && git push origin vX.Y.Z`.
3. Watch the Release workflow. On success, verify:
   - `curl -sI https://www.dragonapp.com/ice-2/appcast.xml` → 200, lists X.Y.Z
   - `brew update && brew livecheck teddychan/tap/ice-2` → X.Y.Z
   - `spctl -a -t install` accepts the downloaded zip's app.
```

- [ ] **Step 2: Commit**

```bash
git add docs/RELEASING.md
git commit -m "Document Ice 2 release prerequisites and flow

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Final verification (after all tasks)

- [ ] In-app feed: `plutil -p Ice/Resources/Info.plist` shows the dragonapp feed + shared key.
- [ ] Live appcast: `curl -sI https://www.dragonapp.com/ice-2/appcast.xml` → 200 with a v2.0.1 item carrying an `edSignature`.
- [ ] Brew: `curl -sI https://github.com/teddychan/ice-2/releases/download/v2.0.1/Ice-2-v2.0.1.zip` → 200; cask `app "Ice 2.app"`, version 2.0.1, correct sha256.
- [ ] No source file references `jordanbaird.github.io/ice-releases` or the old `3nfIGMOD…` key.
- [ ] `release.yml` + `exportOptions.plist` present and valid; `docs/RELEASING.md` lists secrets + runner.

## Notes / risks

- **Owner-gated:** Task 2 needs the Sparkle private key (keychain or pasted secret); Part 2 CI needs the 7 secrets + a runner. Without these the in-app channel still works via the Task 2 backfill; only future automation waits.
- **First CI run** validates the `xcodebuild` export-signing path end-to-end — the one piece not verifiable locally here. If `-exportArchive` complains about signing style, switch `exportOptions.plist` `signingStyle` to `automatic` and drop the manual `CODE_SIGN_*` overrides from the archive step.
- **Bundle id stays `com.jordanbaird.Ice`** — do not change; it preserves users' settings and matches the cask's uninstall/zap paths.
