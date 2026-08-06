#!/usr/bin/env bash
#
# run-debug.sh — build Ice and (re)launch the Debug product as "Ice 2 Debug".
#
# Why: a debug build must not share the installed app's bundle id
# (com.dragonapp.ice), which collides on TCC permissions, the menu-bar manager,
# and the UserDefaults domain. The Debug configuration handles that itself: it
# sets PRODUCT_BUNDLE_IDENTIFIER to com.dragonapp.ice.debug and the display name
# to "Ice 2 Debug", so the built product is already the isolated app and
# `xcodebuild test` gets the same isolation without going through this script.
#
# This script therefore only builds and launches — it deliberately does NOT copy
# the product to a second bundle. An earlier version did, which left two bundles
# claiming com.dragonapp.ice.debug in every DerivedData folder; LaunchServices
# then resolved that id ambiguously and could launch a stale build instead of the
# one just built. One bundle per checkout, one id.
#
# The product keeps PRODUCT_NAME "Ice 2" (its Swift module name, Ice_2, is what
# IceTests imports and what TEST_HOST points at), so the bundle on disk is
# "Ice 2.app" while its user-visible name is "Ice 2 Debug".
#
# Usage: bash scripts/run-debug.sh
#
# This is the Ice-specific instance of a shared convention: every Dragon macOS
# app builds its debug product as "<App> Debug" (<release-bundle-id>.debug).
# Other repos can copy this and change the vars below. See the "dragon-mac-ops"
# skill for the general recipe + rationale.
#
set -euo pipefail

SCHEME="Ice"
CONFIG="Debug"
DEBUG_ID="com.dragonapp.ice.debug"
DEBUG_NAME="Ice 2 Debug"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "==> Building $SCHEME ($CONFIG)…"
xcodebuild -scheme "$SCHEME" -configuration "$CONFIG" \
  -destination 'generic/platform=macOS' \
  build -quiet

products_dir="$(xcodebuild -scheme "$SCHEME" -configuration "$CONFIG" \
  -destination 'generic/platform=macOS' -showBuildSettings 2>/dev/null \
  | awk -F' = ' '/ BUILT_PRODUCTS_DIR = /{print $2; exit}')"

app="$products_dir/Ice 2.app"

if [[ ! -d "$app" ]]; then
  echo "error: built app not found at: $app" >&2
  exit 1
fi

built_id="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app/Contents/Info.plist")"
if [[ "$built_id" != "$DEBUG_ID" ]]; then
  echo "error: built app has bundle id '$built_id', expected '$DEBUG_ID'." >&2
  echo "       The Debug configuration must never build with the release id." >&2
  exit 1
fi

echo "==> Stopping any running debug build…"
pkill -f "$app/Contents/MacOS" 2>/dev/null || true
sleep 1

# Launched by exec rather than `open` on purpose. Older builds of this repo left
# stray "Ice 2 Debug.app" copies in other DerivedData folders that still claim
# this bundle id, and LaunchServices resolves an ambiguous id to whichever copy
# it likes — including a stale one. Exec'ing the binary runs exactly this build.
echo "==> Launching $app"
"$app/Contents/MacOS/Ice 2" >/dev/null 2>&1 &
sleep 1

cat <<EOF

Launched "$DEBUG_NAME" (id $DEBUG_ID) from:
  $app

- Grant Accessibility / Screen Recording to "$DEBUG_NAME" in its Permissions
  window if you want full functionality (separate from your installed Ice 2).
- Ad-hoc signature changes each rebuild, so macOS may ask you to re-grant.
EOF
