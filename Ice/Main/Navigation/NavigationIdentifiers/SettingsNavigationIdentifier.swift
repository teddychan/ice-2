//
//  SettingsNavigationIdentifier.swift
//  Ice
//

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
