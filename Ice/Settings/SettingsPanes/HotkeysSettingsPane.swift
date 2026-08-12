//
//  HotkeysSettingsPane.swift
//  Ice
//

import DragonKit
import SwiftUI

struct HotkeysSettingsPane: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var settings: HotkeysSettings

    var body: some View {
        DragonForm {
            DragonSection {
                Text(L("app.advanced.section.menuBarSections"))
            } content: {
                hotkeyRecorder(forSection: .hidden)
                hotkeyRecorder(forSection: .alwaysHidden)
                hotkeyRecorder(forAction: .toggleSectionDividerIcons)
            }
            DragonSection {
                Text(L("app.hotkeys.section.menuBarItems"))
            } content: {
                hotkeyRecorder(forAction: .searchMenuBarItems)
                hotkeyRecorder(forAction: .temporarilyShowMenuBarItem)
            }
            DragonSection {
                Text(L("app.advanced.section.other"))
            } content: {
                hotkeyRecorder(forAction: .enableIceBar)
                hotkeyRecorder(forAction: .toggleAutoRehide)
                hotkeyRecorder(forAction: .toggleApplicationMenus)
            }
        }
    }

    @ViewBuilder
    private func hotkeyRecorder(forAction action: HotkeyAction) -> some View {
        if let hotkey = settings.hotkey(withAction: action) {
            HotkeyRecorder(hotkey: hotkey) {
                switch action {
                case .toggleHiddenSection:
                    Text(L("app.hotkeys.toggleHidden"))
                case .toggleAlwaysHiddenSection:
                    Text(L("app.hotkeys.toggleAlwaysHidden"))
                case .toggleSectionDividerIcons:
                    Text(L("app.hotkeys.toggleDividerIcons"))
                case .searchMenuBarItems:
                    Text(L("app.hotkeys.search"))
                case .temporarilyShowMenuBarItem:
                    Text(L("app.hotkeys.temporarilyShow"))
                case .enableIceBar:
                    Text(L("app.hotkeys.enableIceBar"))
                case .toggleAutoRehide:
                    Text(L("app.hotkeys.toggleAutoRehide"))
                case .toggleApplicationMenus:
                    Text(L("app.hotkeys.toggleAppMenus"))
                }
            }
        }
    }

    @ViewBuilder
    private func hotkeyRecorder(forSection name: MenuBarSection.Name) -> some View {
        if appState.menuBarManager.section(withName: name)?.isEnabled == true {
            if case .hidden = name {
                hotkeyRecorder(forAction: .toggleHiddenSection)
            } else if case .alwaysHidden = name {
                hotkeyRecorder(forAction: .toggleAlwaysHiddenSection)
            }
        }
    }
}
