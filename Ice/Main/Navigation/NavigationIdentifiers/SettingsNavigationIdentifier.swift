//
//  SettingsNavigationIdentifier.swift
//  Ice
//

import DragonKit

/// The navigation identifier type for the "Settings" interface.
enum SettingsNavigationIdentifier: String, NavigationIdentifier {
    // Sidebar order follows the shared Dragon convention (see dragon-kit README):
    // General → the app's own panes → Permissions → Sync & Backup → What's New →
    // Updates → About → Uninstall. Uninstall is last because it is destructive and
    // rarely used; it is also Ice 2's only in-app uninstall route, since DragonKit 2.0.0
    // dropped Uninstall from the canonical menu-bar dropdown.
    case general = "General"
    case appearance = "Appearance"
    case layout = "Layout"
    case hotkeys = "Hotkeys"
    case advanced = "Advanced"
    case permissions = "Permissions"
    case backup = "Backup & Restore"
    case whatsNew = "What's New"
    case updates = "Updates"
    case about = "About"
    case uninstall = "Uninstall"

    /// The pane that displays live images of the user's menu bar items.
    ///
    /// Capturing those images is expensive and needs Screen Recording, so both the item
    /// cache and the image cache only refresh while this pane is on screen. Naming the
    /// pane once, here, keeps those two call sites tied to the pane that actually renders
    /// the layout bar instead of each hardcoding a case.
    ///
    /// This is not incidental tidiness. Both sites read `.menuBarLayout` until 2.8.0
    /// replaced that case with `.appearance` and `.layout`; the rename sent both to
    /// `.appearance`, the one pane that shows no item images. The images then only
    /// refreshed while the user was looking at a pane that did not display them, and a
    /// failed capture stayed on screen as a placeholder for as long as the Layout pane
    /// was open.
    static let rendersMenuBarItemImages = Self.layout

    /// The sidebar label. Every canonical slot reuses DragonKit's own `DragonKit.pane.*` key
    /// rather than an app copy — including Backup, whose pane is Ice 2's but whose slot the kit
    /// names. §R8 makes an app key beginning `DragonKit.` a violation, and the module bundle wins
    /// the lookup anyway, so a duplicate would be dead weight that merely looks authoritative.
    /// Only Ice 2's own five panes carry `app.` keys.
    var localized: String {
        switch self {
        case .general: L("app.nav.general")
        case .appearance: L("app.nav.appearance")
        case .layout: L("app.nav.layout")
        case .hotkeys: L("app.nav.hotkeys")
        case .advanced: L("app.nav.advanced")
        case .permissions: L("DragonKit.pane.permissions")
        case .backup: L("DragonKit.pane.backup")
        case .whatsNew: L("DragonKit.pane.whatsNew")
        case .updates: L("DragonKit.pane.updates")
        case .about: L("DragonKit.pane.about")
        case .uninstall: L("DragonKit.pane.uninstall")
        }
    }

    var iconResource: IconResource {
        switch self {
        case .general: .systemSymbol("gearshape")
        case .appearance: .systemSymbol("paintpalette")
        case .layout: .systemSymbol("menubar.rectangle")
        case .hotkeys: .systemSymbol("keyboard")
        case .updates: .systemSymbol("arrow.triangle.2.circlepath")
        case .advanced: .systemSymbol("gearshape.2")
        case .permissions: .systemSymbol("lock.shield")
        case .backup: .systemSymbol("externaldrive.badge.timemachine")
        case .whatsNew: .systemSymbol("sparkles")
        case .about: .assetCatalog(.iceCubeStroke)
        case .uninstall: .systemSymbol("trash")
        }
    }
}
