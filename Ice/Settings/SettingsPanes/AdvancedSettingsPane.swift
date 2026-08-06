//
//  AdvancedSettingsPane.swift
//  Ice
//

import DragonKit
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
        DragonForm {
            DragonSection("Menu Bar Sections") {
                enableAlwaysHiddenSection
                showAllSectionsOnUserDrag
                sectionDividerStyle
            }
            DragonSection("Triggers") {
                menuBarTriggers
            }
            DragonSection("Other") {
                hideApplicationMenus
                enableSecondaryContextMenu
                tempShowInterval
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
    private var menuBarTriggers: some View {
        let triggerSettings = appState.settings.triggers
        let currentApplicationName = triggerSettings.candidateApplicationName

        LabeledContent {
            Button("Add Current App") {
                triggerSettings.createFrontmostApplicationTrigger()
            }
            .disabled(currentApplicationName == nil)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("Show items for focused app")
                if let currentApplicationName {
                    Text(currentApplicationName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .dragonAnnotation("When the app becomes focused, Ice shows the hidden section.")

        ForEach(triggerSettings.triggers, id: \.id) { trigger in
            LabeledContent {
                Button("Delete") {
                    triggerSettings.deleteTrigger(trigger)
                }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trigger.name)
                    Text(triggerTargetSummary(trigger))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func triggerTargetSummary(_ trigger: MenuBarTrigger) -> String {
        switch trigger.action {
        case .showHiddenSection:
            "Hidden section"
        }
    }

    @ViewBuilder
    private var hideApplicationMenus: some View {
        Toggle(
            "Hide app menus when showing menu bar items",
            isOn: $settings.hideApplicationMenus
        )
        .dragonAnnotation {
            Text(
                """
                Make more room in the menu bar by hiding the current app menus if \
                needed. macOS requires Ice 2 to make itself visible in the Dock while \
                this setting is in effect.
                """
            )
            .padding(.trailing, 75)
        }
    }

    @ViewBuilder
    private var enableSecondaryContextMenu: some View {
        Toggle(
            "Enable Ice 2 context menus on right click",
            isOn: $settings.enableSecondaryContextMenu
        )
        .dragonAnnotation {
            Text(
                """
                Right-click Ice 2's control items or an empty area of the menu bar to \
                display Ice 2's menu. Disable this setting if you encounter conflicts \
                with other menu bar utilities. When disabled, Option-Command-click \
                in the menu bar opens Ice 2 Settings.
                """
            )
            .padding(.trailing, 75)
        }
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
        .dragonAnnotation("The amount of time to wait before hiding temporarily shown menu bar items.")
    }
}
