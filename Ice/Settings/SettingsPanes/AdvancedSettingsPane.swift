//
//  AdvancedSettingsPane.swift
//  Ice
//

import SwiftUI

struct AdvancedSettingsPane: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var settings: AdvancedSettings
    @State private var maxSliderLabelWidth: CGFloat = 0

    private var menuBarManager: MenuBarManager {
        appState.menuBarManager
    }

    private func formattedToSeconds(_ interval: TimeInterval) -> LocalizedStringKey {
        let formatted = interval.formatted()
        return if interval == 1 {
            LocalizedStringKey(formatted + " second")
        } else {
            LocalizedStringKey(formatted + " seconds")
        }
    }

    var body: some View {
        IceForm {
            IceSection("Menu Bar Sections") {
                enableAlwaysHiddenSection
                showAllSectionsOnUserDrag
                sectionDividerStyle
            }
            IceSection("Other") {
                hideApplicationMenus
                enableSecondaryContextMenu
                showOnHoverDelay
                tempShowInterval
            }
            IceSection("Permissions") {
                allPermissions
            }
        }
    }

    @ViewBuilder
    private var enableAlwaysHiddenSection: some View {
        Toggle(
            "Enable the always-hidden section",
            isOn: $settings.enableAlwaysHiddenSection
        )
    }

    @ViewBuilder
    private var showAllSectionsOnUserDrag: some View {
        Toggle(
            "Show all sections when ⌘ Command + dragging menu bar items",
            isOn: $settings.showAllSectionsOnUserDrag
        )
    }

    @ViewBuilder
    private var sectionDividerStyle: some View {
        IcePicker("Section divider style", selection: $settings.sectionDividerStyle) {
            ForEach(SectionDividerStyle.allCases) { style in
                Text(style.localized).tag(style)
            }
        }
    }

    @ViewBuilder
    private var hideApplicationMenus: some View {
        Toggle(
            "Hide app menus when showing menu bar items",
            isOn: $settings.hideApplicationMenus
        )
        .annotation {
            Text(
                """
                Make more room in the menu bar by hiding the current app menus if \
                needed. macOS requires Ice to make itself visible in the Dock while \
                this setting is in effect.
                """
            )
            .padding(.trailing, 75)
        }
    }

    @ViewBuilder
    private var enableSecondaryContextMenu: some View {
        Toggle(
            "Enable Ice context menus on right click",
            isOn: $settings.enableSecondaryContextMenu
        )
        .annotation {
            Text(
                """
                Right-click Ice's control items or an empty area of the menu bar to \
                display Ice's menu. Disable this setting if you encounter conflicts \
                with other menu bar utilities. When disabled, Option-Command-click \
                in the menu bar opens Ice Settings.
                """
            )
            .padding(.trailing, 75)
        }
    }

    @ViewBuilder
    private var showOnHoverDelay: some View {
        LabeledContent {
            IceSlider(
                formattedToSeconds(settings.showOnHoverDelay),
                value: $settings.showOnHoverDelay,
                in: 0...1,
                step: 0.1
            )
        } label: {
            Text("Show on hover delay")
                .frame(minWidth: maxSliderLabelWidth, alignment: .leading)
                .onFrameChange { frame in
                    maxSliderLabelWidth = max(maxSliderLabelWidth, frame.width)
                }
        }
        .annotation("The amount of time to wait before showing on hover.")
    }

    @ViewBuilder
    private var tempShowInterval: some View {
        LabeledContent {
            IceSlider(
                formattedToSeconds(settings.tempShowInterval),
                value: $settings.tempShowInterval,
                in: 0...60,
                step: 1
            )
        } label: {
            Text("Temporarily shown item delay")
                .frame(minWidth: maxSliderLabelWidth, alignment: .leading)
                .onFrameChange { frame in
                    maxSliderLabelWidth = max(maxSliderLabelWidth, frame.width)
                }
        }
        .annotation("The amount of time to wait before hiding temporarily shown menu bar items.")
    }

    @ViewBuilder
    private var allPermissions: some View {
        ForEach(appState.permissions.allPermissions) { permission in
            LabeledContent {
                if permission.hasPermission {
                    Label {
                        Text("Permission Granted")
                    } icon: {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        Button("Grant Permission") {
                            permission.performRequest()
                        }

                        if permission.mayRequireRelaunch {
                            Button("Relaunch Ice") {
                                appState.relaunch()
                            }
                        }
                    }
                }
            } label: {
                Text(permission.title)
            }
            .frame(height: 22)
        }
    }
}
