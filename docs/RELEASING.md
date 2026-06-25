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

## Notes
- The app bundle id is `com.jordanbaird.Ice` (inherited from upstream). Do not
  change it — it preserves users' existing settings and matches the cask's
  `uninstall`/`zap` paths.
- The first tagged run validates the `xcodebuild` export-signing path. If
  `-exportArchive` errors on signing style, set `signingStyle` to `automatic` in
  `.github/release/exportOptions.plist` and drop the manual `CODE_SIGN_*`
  overrides from the archive step.
