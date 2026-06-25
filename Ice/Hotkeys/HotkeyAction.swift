//
//  HotkeyAction.swift
//  Ice
//

enum HotkeyAction: String, Codable, CaseIterable {
    // Menu Bar Sections
    case toggleHiddenSection = "ToggleHiddenSection"
    case toggleAlwaysHiddenSection = "ToggleAlwaysHiddenSection"
    case toggleSectionDividerIcons = "ToggleSectionDividerIcons"

    // Menu Bar Items
    case searchMenuBarItems = "SearchMenuBarItems"
    case temporarilyShowMenuBarItem = "TemporarilyShowMenuBarItem"

    // Other
    case enableIceBar = "EnableIceBar"
    case toggleAutoRehide = "ToggleAutoRehide"
    case toggleApplicationMenus = "ToggleApplicationMenus"

    @MainActor
    func perform(appState: AppState) {
        switch self {
        case .toggleHiddenSection:
            guard let section = appState.menuBarManager.section(withName: .hidden) else {
                return
            }
            section.toggle()
            // Prevent the section from automatically rehiding after mouse movement.
            if !section.isHidden {
                appState.menuBarManager.showOnHoverAllowed = false
            }
        case .toggleAlwaysHiddenSection:
            guard let section = appState.menuBarManager.section(withName: .alwaysHidden) else {
                return
            }
            section.toggle()
            // Prevent the section from automatically rehiding after mouse movement.
            if !section.isHidden {
                appState.menuBarManager.showOnHoverAllowed = false
            }
        case .toggleSectionDividerIcons:
            let settings = appState.settings.advanced
            settings.sectionDividerStyle = settings.sectionDividerStyle == .noDivider ? .chevron : .noDivider
        case .searchMenuBarItems:
            appState.menuBarManager.searchPanel.toggle()
        case .temporarilyShowMenuBarItem:
            appState.menuBarManager.searchPanel.show(mode: .temporarilyShow)
        case .enableIceBar:
            appState.settings.general.useIceBar.toggle()
        case .toggleAutoRehide:
            appState.settings.general.autoRehide.toggle()
        case .toggleApplicationMenus:
            appState.menuBarManager.toggleApplicationMenus()
        }
    }
}
