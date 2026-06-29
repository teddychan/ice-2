//
//  AppearanceSettingsPane.swift
//  Ice
//

import SwiftUI

/// Combines the menu bar's visual style and its item layout into a single
/// "Appearance" pane, switched between with a segmented control.
struct AppearanceSettingsPane: View {
    @ObservedObject var appearanceManager: MenuBarAppearanceManager
    @ObservedObject var itemManager: MenuBarItemManager
    @ObservedObject var profileSettings: MenuBarLayoutProfilesSettings
    @ObservedObject var spacerManager: MenuBarSpacerManager

    @State private var section: Section = .style

    private enum Section: String, CaseIterable, Identifiable {
        case style = "Style"
        case layout = "Layout"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Appearance section", selection: $section) {
                ForEach(Section.allCases) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            switch section {
            case .style:
                MenuBarAppearanceSettingsPane(appearanceManager: appearanceManager)
            case .layout:
                MenuBarLayoutSettingsPane(
                    itemManager: itemManager,
                    profileSettings: profileSettings,
                    spacerManager: spacerManager
                )
            }
        }
    }
}
