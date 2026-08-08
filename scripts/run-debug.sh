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
# This script therefore builds, stamps and launches — it deliberately does NOT
# copy the product to a second bundle. An earlier version did, which left two
# bundles claiming com.dragonapp.ice.debug in every DerivedData folder;
# LaunchServices then resolved that id ambiguously and could launch a stale build
# instead of the one just built. One bundle per checkout, one id.
#
# PRODUCT_NAME is "Ice 2 Debug" in the Debug configuration, so the bundle on disk,
# its executable, CFBundleName and CFBundleDisplayName all read "Ice 2 Debug" —
# there is nowhere left for the name "Ice 2" to appear on a debug build.
# PRODUCT_MODULE_NAME is pinned to Ice_2 so the Swift module keeps the name
# IceTests imports; TEST_HOST points at the Debug product by its own name.
#
# What the script stamps afterwards (both need the built bundle to exist):
#   CFBundleVersion             the git commit count, never a hardcoded number
#   CFBundleShortVersionString  suffixed "(Debug)"
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

app="$products_dir/$DEBUG_NAME.app"

if [[ ! -d "$app" ]]; then
  echo "error: built app not found at: $app" >&2
  exit 1
fi

plist="$app/Contents/Info.plist"
pb=/usr/libexec/PlistBuddy

built_id="$("$pb" -c "Print :CFBundleIdentifier" "$plist")"
if [[ "$built_id" != "$DEBUG_ID" ]]; then
  echo "error: built app has bundle id '$built_id', expected '$DEBUG_ID'." >&2
  echo "       The Debug configuration must never build with the release id." >&2
  exit 1
fi

echo "==> Stopping any running debug build…"
pkill -f "$app/Contents/MacOS" 2>/dev/null || true
sleep 1

# Build number is the git commit count, never the hardcoded CURRENT_PROJECT_VERSION
# in the project — that value goes stale the moment anyone commits without bumping
# it, and a debug build reporting a stale number is worse than useless when you are
# trying to tell two builds apart. Same rule the release scripts follow.
build_number="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
"$pb" -c "Set :CFBundleVersion $build_number" "$plist"

# The commit's own timestamp, which DragonKit renders after the build number. The
# release workflow passes it as the DRAGON_COMMIT_DATE build setting; a plain local
# build defines no such setting, so stamp it here or a debug About pane shows the
# build number with no date beside it.
commit_date="$(git log -1 --format=%cI 2>/dev/null || true)"
if [[ -n "$commit_date" ]]; then
  "$pb" -c "Set :DragonCommitDate $commit_date" "$plist" 2>/dev/null \
    || "$pb" -c "Add :DragonCommitDate string $commit_date" "$plist"
fi

# Mark the version itself, not just the name: the About pane and any log line that
# reports a version should say "(Debug)" outright, so a screenshot or a log excerpt
# can never be mistaken for the release build. Derived from whatever the project's
# MARKETING_VERSION currently is, so it cannot drift out of sync on a version bump.
short_version="$("$pb" -c "Print :CFBundleShortVersionString" "$plist")"
if [[ "$short_version" != *"(Debug)" ]]; then
  short_version="$short_version (Debug)"
  "$pb" -c "Set :CFBundleShortVersionString $short_version" "$plist"
fi

# Editing Info.plist invalidates the code signature, so re-sign. Ad-hoc and deep:
# the bundle carries Sparkle.framework and the MenuBarItemService XPC, and a broken
# signature on either makes the app fail to launch rather than fail visibly.
echo "==> Re-signing after stamping $short_version ($build_number)…"
codesign --force --deep --sign - "$app" >/dev/null 2>&1

# Launched by exec rather than `open` on purpose. Older builds of this repo left
# stray "Ice 2 Debug.app" copies in other DerivedData folders that still claim
# this bundle id, and LaunchServices resolves an ambiguous id to whichever copy
# it likes — including a stale one. Exec'ing the binary runs exactly this build.
echo "==> Launching $app"
"$app/Contents/MacOS/$DEBUG_NAME" >/dev/null 2>&1 &
sleep 1

cat <<EOF

Launched "$DEBUG_NAME" $short_version (build $build_number), id $DEBUG_ID, from:
  $app

- Grant Accessibility / Screen Recording to "$DEBUG_NAME" in its Permissions
  window if you want full functionality (separate from your installed Ice 2).
- Ad-hoc signature changes each rebuild, so macOS may ask you to re-grant.
EOF
