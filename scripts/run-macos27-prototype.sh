#!/bin/bash
set -euo pipefail

if [[ $# -gt 1 || ( $# -eq 1 && "$1" != "--self-test" ) ]]; then
    echo 'Usage: run-macos27-prototype.sh [--self-test]' >&2
    exit 2
fi

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
prototype_dir="$(mktemp -d /tmp/ice2-macos27-prototype.XXXXXX)"
prototype_app="$prototype_dir/Ice 2 macOS 27 Prototype.app"
mkdir -p "$prototype_app/Contents/MacOS"
cat > "$prototype_app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.dragonapp.ice.macos27-prototype</string>
<key>CFBundleExecutable</key><string>macos27-prototype</string>
<key>CFBundleName</key><string>Ice 2 macOS 27 Prototype</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
</dict></plist>
PLIST

# Select a matching compiler/SDK; a newer CommandLineTools SDK may not be
# readable by the currently selected Xcode's linker.
xcrun clang -isysroot "$(xcrun --sdk macosx --show-sdk-path)" \
    -fobjc-arc -Wall -Wextra -Werror -framework AppKit -framework ApplicationServices \
    "$repo_dir/scripts/macos27-prototype.m" \
    -o "$prototype_app/Contents/MacOS/macos27-prototype"
codesign --force --sign - "$prototype_app"
echo "Prototype: $prototype_app" >&2
"$prototype_app/Contents/MacOS/macos27-prototype" "$@"
