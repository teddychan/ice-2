#!/usr/bin/env bash
#
# run-debug.sh — build Ice, re-id the product as a standalone "Ice 2 Debug.app"
# (bundle id com.jordanbaird.Ice.debug), ad-hoc sign it, and (re)launch it.
#
# Why: the debug build shares the installed app's bundle id (com.jordanbaird.Ice),
# which collides on TCC permissions, the menu-bar manager, and the UserDefaults
# domain. Re-iding to com.jordanbaird.Ice.debug gives the debug build its own
# permissions and settings so it can run next to an installed Ice 2 without
# conflict. The bundled MenuBarItemService XPC keeps its original id (the host
# resolves it by that id from inside the bundle), so it must NOT be changed.
#
# Usage: bash scripts/run-debug.sh
#
# This is the Ice-specific instance of a shared convention: every Dragon macOS
# app keeps a scripts/run-debug.sh that re-ids its debug build as "<App> Debug"
# (<release-bundle-id>.debug). Other repos can copy this and change the four
# vars below. See the "dragon-mac-ops" skill for the general recipe + rationale.
#
set -euo pipefail

SCHEME="Ice"
CONFIG="Debug"
DEBUG_ID="com.jordanbaird.Ice.debug"
DEBUG_NAME="Ice 2 Debug"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "==> Building $SCHEME ($CONFIG)…"
xcodebuild -scheme "$SCHEME" -configuration "$CONFIG" \
  -destination 'generic/platform=macOS' \
  build CODE_SIGNING_ALLOWED=NO -quiet

products_dir="$(xcodebuild -scheme "$SCHEME" -configuration "$CONFIG" \
  -destination 'generic/platform=macOS' -showBuildSettings CODE_SIGNING_ALLOWED=NO 2>/dev/null \
  | awk -F' = ' '/ BUILT_PRODUCTS_DIR = /{print $2; exit}')"

src="$products_dir/Ice 2.app"
dst="$products_dir/$DEBUG_NAME.app"

if [[ ! -d "$src" ]]; then
  echo "error: built app not found at: $src" >&2
  exit 1
fi

echo "==> Stopping any running debug build…"
pkill -f "$DEBUG_NAME.app/Contents/MacOS" 2>/dev/null || true
sleep 1

echo "==> Re-iding copy as $DEBUG_NAME ($DEBUG_ID)…"
rm -rf "$dst"
cp -R "$src" "$dst"

pb=/usr/libexec/PlistBuddy
"$pb" -c "Set :CFBundleIdentifier $DEBUG_ID" "$dst/Contents/Info.plist"
"$pb" -c "Set :CFBundleName $DEBUG_NAME" "$dst/Contents/Info.plist"
if ! "$pb" -c "Set :CFBundleDisplayName $DEBUG_NAME" "$dst/Contents/Info.plist" 2>/dev/null; then
  "$pb" -c "Add :CFBundleDisplayName string $DEBUG_NAME" "$dst/Contents/Info.plist"
fi

echo "==> Ad-hoc signing…"
codesign --force --deep --sign - "$dst" >/dev/null 2>&1

echo "==> Launching $dst"
open "$dst"

cat <<EOF

Launched "$DEBUG_NAME" (id $DEBUG_ID).
- Grant Accessibility / Screen Recording to "$DEBUG_NAME" in its Permissions
  window if you want full functionality (separate from your installed Ice 2).
- Ad-hoc signature changes each rebuild, so macOS may ask you to re-grant.
EOF
