//
//  SettingsView.swift
//  Ice
//

import DragonKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var navigationState: AppNavigationState
    @Environment(\.appearsActive) private var appearsActive
    @Environment(\.sidebarRowSize) private var sidebarRowSize

    private let sidebarPadding: CGFloat = 3

    private var sidebarWidth: CGFloat {
        switch sidebarRowSize {
        case .small: 200
        case .medium: 220
        case .large: 240
        @unknown default: 220
        }
    }

    private var sidebarTextStyle: some ShapeStyle {
        appearsActive ? .primary : .secondary
    }

    private var navigationTitle: LocalizedStringKey {
        navigationState.settingsNavigationIdentifier.localized
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationTitle(navigationTitle)
    }

    /// The "meta" panes, grouped separately at the bottom of the sidebar.
    private let metaIdentifiers: [SettingsNavigationIdentifier] = [.whatsNew, .updates, .about, .uninstall]

    /// The functional panes, shown at the top of the sidebar.
    private var primaryIdentifiers: [SettingsNavigationIdentifier] {
        SettingsNavigationIdentifier.allCases.filter { !metaIdentifiers.contains($0) }
    }

    @ViewBuilder
    private var sidebar: some View {
        List(selection: $navigationState.settingsNavigationIdentifier) {
            Section {
                ForEach(primaryIdentifiers) { identifier in
                    sidebarItem(for: identifier)
                }
            } header: {
                Text("Ice 2")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundStyle(sidebarTextStyle)
                    .padding(.leading, sidebarPadding)
                    .padding(.bottom, 8)
            }
            .collapsible(false)

            Section {
                ForEach(metaIdentifiers) { identifier in
                    sidebarItem(for: identifier)
                }
            }
            .collapsible(false)
        }
        .scrollDisabled(true)
        .toolbar(removing: .sidebarToggle)
        .toolbar {
            sidebarToolbarSpacer
        }
        .navigationSplitViewColumnWidth(sidebarWidth)
    }

    @ViewBuilder
    private func sidebarItem(for identifier: SettingsNavigationIdentifier) -> some View {
        Label {
            Text(identifier.localized)
                .foregroundStyle(sidebarTextStyle)
        } icon: {
            identifier.iconResource.view
                .foregroundStyle(sidebarTextStyle)
                .padding(sidebarPadding)
        }
        .tag(identifier)
    }

    @ToolbarContentBuilder
    private var sidebarToolbarSpacer: some ToolbarContent {
        ToolbarSpacer(.flexible)
    }

    @ViewBuilder
    private var detailView: some View {
        settingsPane
            .scrollEdgeEffectStyle(.hard, for: .top)
    }

    @ViewBuilder
    private var settingsPane: some View {
        switch navigationState.settingsNavigationIdentifier {
        case .general:
            GeneralSettingsPane(settings: appState.settings.general)
        case .appearance:
            MenuBarAppearanceSettingsPane(appearanceManager: appState.appearanceManager)
        case .layout:
            MenuBarLayoutSettingsPane(
                itemManager: appState.itemManager,
                profileSettings: appState.settings.layoutProfiles,
                spacerManager: appState.spacerManager
            )
        case .hotkeys:
            HotkeysSettingsPane(settings: appState.settings.hotkeys)
        case .updates:
            UpdatesSettingsPane(updatesManager: appState.updatesManager)
        case .advanced:
            AdvancedSettingsPane(settings: appState.settings.advanced)
        case .permissions:
            PermissionsPane(permissions: [.accessibility(), .screenRecording()])
        case .backup:
            IceBackupSettingsPane()
        case .whatsNew:
            WhatsNewPane(content: WhatsNewConfig.content)
        case .about:
            AboutPane(content: AboutConfig.content)
        case .uninstall:
            // DragonKit's pane confirms inline and runs the teardown itself; Cancel goes back
            // to General. `paneBody` is the pane's content — Ice 2 owns its own sidebar, so it
            // renders that directly instead of going through the kit's `SettingsShell`.
            UninstallSettingsPane(
                config: IceUninstallConfig.config,
                onCancel: { navigationState.settingsNavigationIdentifier = .general }
            )
            .paneBody
        }
    }
}
