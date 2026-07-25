<div align="center">
    <img src="Ice/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="160" height="160" alt="Ice 2 app icon">
    <h1>Ice 2</h1>
    <p><strong>Menu bar management for macOS</strong></p>
</div>

Ice 2 hides and shows the items in your macOS menu bar. It splits the menu bar into
visible, hidden, and always-hidden sections that you reveal by click, hover, scroll,
or hotkey. Beyond hiding items, it customizes the menu bar's appearance, saves layout
profiles, and searches your items.

## Screenshots

![Banner](https://github.com/user-attachments/assets/4423085c-4e4b-4f3d-ad0f-90a217c03470)

#### Show hidden menu bar items below the menu bar

![Ice 2 Bar](https://github.com/user-attachments/assets/f1429589-6186-4e1b-8aef-592219d49b9b)

#### Drag-and-drop interface to arrange menu bar items

![Menu Bar Layout](https://github.com/user-attachments/assets/095442ba-f2d0-4bb4-9632-91e26ef8d45b)

#### Customize the menu bar's appearance

![Menu Bar Appearance](https://github.com/user-attachments/assets/8c22c185-c3d2-49bb-971e-e1fc17df04b3)

#### Menu bar item search

![Menu Bar Item Search](https://github.com/user-attachments/assets/d1a7df3a-4989-4077-a0b1-8e7d5a1ba5b8)

#### Custom menu bar item spacing

![Menu Bar Item Spacing](https://github.com/user-attachments/assets/b196aa7e-184a-4d4c-b040-502f4aae40a6)

[![Download](https://img.shields.io/badge/download-latest-brightgreen?style=flat-square)](https://github.com/teddychan/ice-2/releases/latest)
![Platform](https://img.shields.io/badge/platform-macOS-blue?style=flat-square)
![Requirements](https://img.shields.io/badge/requirements-macOS%2026%2B-fa4e49?style=flat-square)
[![Website](https://img.shields.io/badge/Website-dragonapp.com-015FBA?style=flat-square)](https://www.dragonapp.com/ice-2/)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue?style=flat-square)](LICENSE)

## Contents

- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Install](#install)
- [Features](#features)
- [Menu bar sections](#menu-bar-sections)
- [Troubleshooting](#troubleshooting)
- [Building from source](#building-from-source)
- [Contributing](#contributing)
- [Credits](#credits)
- [License](#license)

## Requirements

- macOS 26 (Tahoe) or later.
- An Apple Silicon Mac. Ice 2 is built for arm64 only; if you are on an Intel Mac,
  stay on version 2.4.1, which remains available on the
  [releases page](https://github.com/teddychan/ice-2/releases).
- Accessibility and Screen Recording permissions. Ice 2 asks for both on first
  launch and cannot manage menu bar items without them.

## Install

### Homebrew

```sh
brew install --cask teddychan/tap/ice-2
```

### Manual

Download the `Ice-2-vX.Y.Z.zip` file from the
[latest release](https://github.com/teddychan/ice-2/releases/latest) and move the
unzipped app into your `Applications` folder.

### Uninstall

Quit Ice 2 before uninstalling.

If you installed with Homebrew:

```sh
brew uninstall --cask teddychan/tap/ice-2
```

If you installed manually, delete `Ice 2.app` from your `Applications` folder.

To also remove Ice 2 settings and cached data:

```sh
rm -rf ~/Library/Application\ Support/com.dragonapp.ice \
       ~/Library/Caches/com.dragonapp.ice \
       ~/Library/HTTPStorages/com.dragonapp.ice \
       ~/Library/Preferences/com.dragonapp.ice.plist \
       ~/Library/Saved\ Application\ State/com.dragonapp.ice.savedState
```

## Features

> [!NOTE]
> Ice 2 is an independent, open-source fork of [Ice](https://github.com/jordanbaird/Ice) — the menu bar manager originally created by [Jordan Baird](https://github.com/jordanbaird) — now actively maintained by [Teddy Chan](https://github.com/teddychan) and carried forward to support modern macOS. Download the latest release [here](https://github.com/teddychan/ice-2/releases/latest) and see the roadmap below for upcoming features.

### Menu bar item management

- [x] Hide menu bar items
- [x] "Always-hidden" menu bar section
- [x] Show hidden menu bar items when hovering over the menu bar
- [x] Show hidden menu bar items when an empty area in the menu bar is clicked
- [x] Show hidden menu bar items by scrolling or swiping in the menu bar
- [x] Automatically rehide menu bar items
- [x] Hide application menus when they overlap with shown menu bar items
- [x] Drag and drop interface to arrange individual menu bar items
- [x] Display hidden menu bar items in a separate bar (e.g. for MacBooks with the notch)
- [x] Search menu bar items
- [x] Menu bar item spacing (BETA)
- [x] Profiles for menu bar layout
- [x] Individual spacer items
- [x] Menu bar item groups
- [x] Show menu bar items when trigger conditions are met

### Menu bar appearance

- [x] Menu bar tint (solid and gradient)
- [x] Menu bar shadow
- [x] Menu bar border
- [x] Custom menu bar shapes (rounded and/or split)
- [x] Different settings for light/dark mode
- [x] Remove background behind menu bar
- [x] Rounded screen corners

### Hotkeys

- [x] Toggle individual menu bar sections
- [x] Show the search panel
- [x] Enable/disable the Ice 2 Bar
- [x] Show/hide section divider icons
- [x] Toggle application menus
- [x] Enable/disable auto rehide
- [x] Temporarily show individual menu bar items

### Other

- [x] Launch at login
- [x] Automatic updates
- [x] Back up & restore settings to a folder you choose (sync across Macs via Dropbox / iCloud Drive / Google Drive)
- [ ] Menu bar widgets

## Menu bar sections

Ice 2 divides the menu bar into three sections — **Visible**, **Hidden**, and
**Always-Hidden** — and installs one control item per enabled section as a divider
between them. macOS adds new items to the left end of the menu bar, which is where
the always-hidden section lives.

- **Click** Ice 2's icon to toggle its section.
- **Option-click** it to toggle the always-hidden section.
- **Control-click** it to open Ice 2's menu. Turn this off under
  **Settings ▸ Advanced ▸ Other**.
- **Command-drag** an item along the menu bar to move it into another section.

The always-hidden section is enabled by default. Turn it off, or change how the
dividers look, under **Settings ▸ Advanced ▸ Menu Bar Sections**.

## Troubleshooting

Common problems and their fixes are collected in
[FREQUENT_ISSUES.md](FREQUENT_ISSUES.md) — items landing in the always-hidden
section, items that appear to have been removed, item order not being remembered,
and the `Ice 2 cannot arrange menu bar items in automatically hidden menu bars`
error.

If Ice 2 cannot see or move your menu bar items, check that it still has
Accessibility and Screen Recording permission in **System Settings ▸ Privacy &
Security**. Granting Screen Recording may require relaunching Ice 2.

### Why does Ice 2 require macOS 26 and later?

Ice 2 uses a number of system APIs that are available starting in macOS 26, and it
builds against the macOS 26 SDK. As such, there are no plans to support earlier
versions of macOS. Older releases remain downloadable on the
[releases page](https://github.com/teddychan/ice-2/releases).

### Can I back up, restore, or sync my settings?

Yes. Open **Settings ▸ Backup & Restore** and choose a backup folder. Use **Back Up Now** to save a snapshot of all your Ice 2 settings (layout profiles, item groups, spacers, triggers, hotkeys, and appearance), and Ice 2 also backs up automatically when you quit. The newest 10 backups are kept; you can restore any of them with one click (Ice 2 relaunches to apply).

To **sync across Macs** or move to a new Mac, point the backup folder at a synced location such as Dropbox, iCloud Drive, or Google Drive — your settings then appear on your other Macs, where you can restore them.

## Building from source

Ice 2 is a plain Xcode project — no package manager step is required.

1. Clone the repo and open `Ice.xcodeproj` in Xcode 26 or later (the project targets
   the macOS 26 SDK and builds for arm64).
2. Select the **Ice** scheme and run. The product is named `Ice 2.app`.

From the command line:

```sh
xcodebuild -scheme Ice -configuration Debug -destination 'generic/platform=macOS' build
xcodebuild -scheme Ice -destination 'platform=macOS' test
```

The **Ice** scheme's test action runs the `IceTests` unit-test target.

To try a local build alongside an installed copy of Ice 2, use the debug runner. It
builds the **Ice** scheme, re-ids the product as `Ice 2 Debug.app`
(`com.dragonapp.ice.debug`), ad-hoc signs it, and launches it, so it gets its own
permissions and settings instead of colliding with the release app:

```sh
bash scripts/run-debug.sh
```

Swift sources are linted with [SwiftLint](https://github.com/realm/SwiftLint)
(`.swiftlint.yml`); CI runs `swiftlint lint --strict` on every pull request that
touches Swift files.

## Contributing

Issues and pull requests are welcome.

- Read the [Code of Conduct](CODE_OF_CONDUCT.md) before taking part.
- Check [FREQUENT_ISSUES.md](FREQUENT_ISSUES.md) first — several common reports are
  already answered there.
- Keep the build lint-clean; CI runs SwiftLint in strict mode.
- Release mechanics (tagging, signing, notarization, the Sparkle appcast, and the
  Homebrew cask) are documented in [docs/RELEASING.md](docs/RELEASING.md).

## Credits

Ice 2 is a fork of [Ice](https://github.com/jordanbaird/Ice), created by [Jordan Baird](https://github.com/jordanbaird). All credit for the original app goes to him and its contributors. Ice 2 is currently maintained by [Teddy Chan](https://github.com/teddychan).

## License

Ice 2 is available under the [GPL-3.0 license](LICENSE), the same license as the original Ice.
