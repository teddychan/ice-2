//
//  SettingsView.swift
//  Ice
//

import DragonKit
import DragonKitUpdates
import SwiftUI

/// Ice 2's settings window.
///
/// **This shell is deliberately Ice 2's own, not DragonKit's `SettingsShell`.** The kit's shell
/// is the data-driven generalization of this view, and adopting it is the obvious move — but it
/// models one flat sidebar section of `Image(systemName:)` rows against a `String?` selection,
/// and five things here have no expression in it:
///
/// - the second sidebar group (What's New, Updates, About, Uninstall sit apart at the bottom);
/// - `.assetCatalog(.iceCubeStroke)` for About — `SettingsPane` exposes only
///   `var systemImage: String`, so the kit cannot name a non-SF-Symbol icon at all;
/// - the sidebar width tracking `\.sidebarRowSize`;
/// - the row text dimming with `\.appearsActive` when the window is in the background;
/// - `.navigationTitle` following the selected pane, and a non-optional selection, so there is
///   no "Select a setting" empty state to render.
///
/// The icon is the smallest of the five, which is why an icon abstraction on `SettingsPane`
/// would not have unblocked this on its own — it would have left four. Teaching the kit all five
/// is a much larger, speculative change than one app needs, and nothing requires it: §R4 governs
/// design *primitives* (`DragonForm` / `DragonSection` / `.dragonAnnotation`), which this pane
/// tree already uses throughout; §R5 requires the kit's *panes*, which are rendered below via
/// `.paneBody`; and §R9 reads pane order from whatever file the app names in
/// `.dragon-conformance.json`. So the app shell stays, and the asset-catalog icon is not
/// silently dropped to fit a protocol.
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

    private var navigationTitle: String {
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
                Text(Constants.displayName)
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
            // DragonKit's pane owns the auto-check / auto-download toggles, the
            // "Check for Updates…" button, and the last-checked time. As with Uninstall,
            // Ice 2 renders `paneBody` directly because it owns its own sidebar.
            UpdatesSettingsPane(updater: appState.updatesManager.updater)
                .paneBody
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
