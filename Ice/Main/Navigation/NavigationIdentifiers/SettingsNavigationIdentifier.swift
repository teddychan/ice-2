//
//  SettingsNavigationIdentifier.swift
//  Ice
//

/// The navigation identifier type for the "Settings" interface.
enum SettingsNavigationIdentifier: String, NavigationIdentifier {
    // Sidebar order follows the shared Dragon convention (see dragon-kit README):
    // General → the app's own panes → Permissions → Sync & Backup → What's New →
    // Updates → About. (Ice has no Uninstall pane — uninstall lives in the menu-bar menu.)
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
        }
    }
}
