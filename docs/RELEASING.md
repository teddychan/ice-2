# Releasing Ice 2

Pushing a `vX.Y.Z` tag to `teddychan/ice-2` triggers
`.github/workflows/release.yml`, which builds, Developer ID-signs, notarizes,
and staples the app, uploads `Ice-2-vX.Y.Z.zip` to the GitHub Release,
publishes the signed Sparkle appcast to `docs/ice-2/appcast.xml` **in this
repo**, and bumps the Homebrew cask `teddychan/tap/ice-2`.

The app-owned feed is the one the app reads — `SUFeedURL` in
`App/Info.plist` is
`https://raw.githubusercontent.com/teddychan/ice-2/main/docs/ice-2/appcast.xml`.
The same appcast is also copied to `teddychan/www.dragonapp.com`
(`https://www.dragonapp.com/ice-2/appcast.xml`), but that copy is only a
**temporary mirror** for installs still on v2.14.3 or older, and is scheduled
to be dropped at the next minor release. See the `appcast_mirror_repo` comment
in `.github/workflows/release.yml` — that comment is the source of truth for
the migration and its retirement trigger.

## One-time setup

### 1. Repository secrets (Settings → Secrets and variables → Actions)
Reuse the same values already on `clipmenu-2` (same Apple Team `4AF3KGGV29`):

- `DEVELOPER_ID_CERT_P12_BASE64`
- `DEVELOPER_ID_CERT_PASSWORD`
- `NOTARY_KEY_P8_BASE64`
- `NOTARY_KEY_ID`
- `NOTARY_ISSUER_ID`
- `PUBLIC_RELEASE_TOKEN` (PAT with write access to `teddychan/homebrew-tap`
  and — while the mirror lasts — `teddychan/www.dragonapp.com`. The appcast in
  *this* repo is published with the built-in `GITHUB_TOKEN`, which
  `permissions: contents: write` in `release.yml` covers.)
- `SPARKLE_EDDSA_PRIVATE_KEY` (the shared EdDSA private key; its public half
  `p+F/ivF5bAYcmuNuCMNHcRv123A6LHFpCBagFm7Adu8=` is in `App/Info.plist`)

### 2. Runner
The workflow runs on a **GitHub-hosted** macOS runner — public repos get free
Actions minutes, so no self-hosted runner is required. Ice 2 targets the macOS
26 SDK, which the shared pipeline's default `macos-15` image lacks, so the
caller passes `swiftpm_runner: macos-26`; despite the name that input drives
the job's `runs-on` for all build kinds, not just swiftpm. The "Select Xcode"
step then picks the newest Xcode on the image.

## Cutting a release
1. Bump `MARKETING_VERSION` in `Ice.xcodeproj` and commit.
2. `git tag vX.Y.Z && git push origin vX.Y.Z`.
3. Watch the Release workflow. On success, verify:
   - The feed the app actually reads — prints X.Y.Z:

     ```bash
     curl -s https://raw.githubusercontent.com/teddychan/ice-2/main/docs/ice-2/appcast.xml | grep sparkle:shortVersionString
     ```

     Check this URL, not `https://www.dragonapp.com/ice-2/appcast.xml`: the
     site copy is only the mirror, and it is served by the GitHub Pages CDN,
     which can keep returning the previous appcast for minutes after a
     successful publish — which looks exactly like a failed release.
   - `brew update && brew livecheck teddychan/tap/ice-2` → X.Y.Z
   - `spctl -a -t install` accepts the downloaded zip's app.

## Notes
- The app bundle id is `com.dragonapp.ice` (rebranded from the upstream
  `com.jordanbaird.Ice`). Keep the cask's `uninstall`/`zap` paths in sync with
  this id.
- The first tagged run validates the `xcodebuild` export-signing path. If
  `-exportArchive` errors on signing style, set `signingStyle` to `automatic` in
  `.github/release/exportOptions.plist` and drop the manual `CODE_SIGN_*`
  overrides from the archive step.
