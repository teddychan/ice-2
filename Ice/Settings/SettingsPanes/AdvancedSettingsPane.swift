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

    var body: some View {
        DragonForm {
            DragonSection {
                Text(L("app.advanced.section.menuBarSections"))
            } content: {
                enableAlwaysHiddenSection
                showAllSectionsOnUserDrag
                sectionDividerStyle
            }
            DragonSection {
                Text(L("app.advanced.section.triggers"))
            } content: {
                menuBarTriggers
            }
            DragonSection {
                Text(L("app.advanced.section.other"))
            } content: {
                hideApplicationMenus
                enableSecondaryContextMenu
                tempShowInterval
            }
        }
    }

    @ViewBuilder
    private var enableAlwaysHiddenSection: some View {
        Toggle(
            L("app.advanced.enableAlwaysHidden"),
            isOn: $settings.enableAlwaysHiddenSection
        )
    }

    @ViewBuilder
    private var showAllSectionsOnUserDrag: some View {
        Toggle(
            L("app.advanced.showAllOnDrag"),
            isOn: $settings.showAllSectionsOnUserDrag
        )
    }

    @ViewBuilder
    private var sectionDividerStyle: some View {
        IcePicker(L("app.advanced.dividerStyle"), selection: $settings.sectionDividerStyle) {
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
            Button(L("app.advanced.addCurrentApp")) {
                triggerSettings.createFrontmostApplicationTrigger()
            }
            .disabled(currentApplicationName == nil)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(L("app.advanced.showForFocusedApp"))
                if let currentApplicationName {
                    Text(currentApplicationName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .dragonAnnotation { Text(L("app.advanced.showForFocusedApp.note")) }

        ForEach(triggerSettings.triggers, id: \.id) { trigger in
            LabeledContent {
                Button(L("app.common.delete")) {
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
            L("app.advanced.trigger.hiddenSection")
        }
    }

    @ViewBuilder
    private var hideApplicationMenus: some View {
        Toggle(
            L("app.advanced.hideAppMenus"),
            isOn: $settings.hideApplicationMenus
        )
        .dragonAnnotation {
            Text(L("app.advanced.hideAppMenus.note"))
                .padding(.trailing, 75)
        }
    }

    @ViewBuilder
    private var enableSecondaryContextMenu: some View {
        Toggle(
            L("app.advanced.secondaryContextMenu"),
            isOn: $settings.enableSecondaryContextMenu
        )
        .dragonAnnotation {
            Text(L("app.advanced.secondaryContextMenu.note"))
                .padding(.trailing, 75)
        }
    }

    @ViewBuilder
    private var tempShowInterval: some View {
        LabeledContent {
            IceSlider(
                formattedSeconds(settings.tempShowInterval),
                value: $settings.tempShowInterval,
                in: 0...60,
                step: 1
            )
        } label: {
            Text(L("app.advanced.tempShowInterval"))
                .frame(minWidth: maxSliderLabelWidth, alignment: .leading)
                .onFrameChange { frame in
                    maxSliderLabelWidth = max(maxSliderLabelWidth, frame.width)
                }
        }
        .dragonAnnotation { Text(L("app.advanced.tempShowInterval.note")) }
    }
}
