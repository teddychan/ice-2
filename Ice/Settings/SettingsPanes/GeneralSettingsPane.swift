//
//  GeneralSettingsPane.swift
//  Ice
//

import DragonKit
import SwiftUI

struct GeneralSettingsPane: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var settings: GeneralSettings
    @State private var isApplyingItemSpacingOffset = false
    @State private var tempItemSpacingOffset: CGFloat = 0
    /// Mirror of the OS login-item registration, re-read whenever the pane appears so a
    /// change made in System Settings shows up here.
    @State private var launchesAtLogin = LoginItem.isEnabled

    /// A single toggle backing both hover-to-show triggers (empty menu bar and Ice 2 icon).
    private var showOnHover: Binding<Bool> {
        Binding(
            get: { settings.showOnHoverEmptyMenuBar || settings.showOnHoverOverIceIcon },
            set: { newValue in
                settings.showOnHoverEmptyMenuBar = newValue
                settings.showOnHoverOverIceIcon = newValue
            }
        )
    }

    /// A single delay shared by both hover-to-show triggers.
    private var hoverDelay: Binding<TimeInterval> {
        Binding(
            get: { settings.showOnHoverEmptyMenuBarDelay },
            set: { newValue in
                settings.showOnHoverEmptyMenuBarDelay = newValue
                settings.showOnHoverOverIceIconDelay = newValue
            }
        )
    }

    private var itemSpacingOffsetLabel: String {
        switch tempItemSpacingOffset {
        case -16: L("app.general.spacing.none")
        case 0: L("app.general.spacing.default")
        case 16: L("app.general.spacing.max")
        default: tempItemSpacingOffset.formatted()
        }
    }

    var body: some View {
        DragonForm {
            DragonSection {
                appOptions
                iceIconOptions
            }
            DragonSection {
                Text(L("app.general.section.showHiddenItems"))
            } content: {
                showOptions
            }
            DragonSection {
                Text(L("app.general.section.rehide"))
            } content: {
                rehideOptions
            }
            DragonSection {
                Text(L("app.general.section.iceBar"))
            } content: {
                iceBarOptions
            }
            DragonSection {
                advancedOptions
            }
        }
    }

    // MARK: App Options

    /// Launch at login, via DragonKit's `LoginItem` — the single code path every Dragon app
    /// (and the shared uninstall flow) uses to drive `SMAppService.mainApp`.
    ///
    /// The language picker is DragonKit's `LanguagePicker`, called bare: Ice 2 ships every
    /// locale the kit does, and CONFORMANCE.md §R13 requires the offered set to equal the
    /// shipped set exactly, so the kit's default of `DragonLanguage.selectable` is the correct
    /// list. `onChange` is left `nil` — Ice 2 resolves its own strings through `L(_:)` and the
    /// settings window is wrapped in `.dragonLocalized()`, so the switch happens in place with
    /// no relaunch.
    @ViewBuilder
    private var appOptions: some View {
        Toggle(L("app.general.launchAtLogin"), isOn: Binding(
            get: { launchesAtLogin },
            set: { newValue in
                LoginItem.setEnabled(newValue)
                // Read the status back: registration can fail, and the toggle should show
                // what the OS actually did rather than what was asked for.
                launchesAtLogin = LoginItem.isEnabled
            }
        ))
        .onAppear { launchesAtLogin = LoginItem.isEnabled }

        LanguagePicker()
    }

    // MARK: Ice Icon Options

    @ViewBuilder
    private var iceIconOptions: some View {
        Toggle(L("app.general.showIceIcon"), isOn: $settings.showIceIcon)
            .dragonAnnotation { Text(L("app.general.showIceIcon.note")) }
    }

    // MARK: Ice Bar Options

    @ViewBuilder
    private var iceBarOptions: some View {
        useIceBar
        if settings.useIceBar {
            iceBarLocationPicker
        }
        DisclosureGroup {
            autoEnableIceBar
            if settings.autoEnableIceBar {
                iceBarAutoEnableModePicker
                if settings.iceBarAutoEnableMode == .screenWidth {
                    iceBarDisplayWidthThreshold
                }
            }
        } label: {
            Text(L("app.general.autoIceBar"))
        }
    }

    // MARK: Advanced Options

    @ViewBuilder
    private var advancedOptions: some View {
        DisclosureGroup {
            spacingOptions
        } label: {
            Text(L("app.general.advanced"))
        }
    }

    @ViewBuilder
    private var useIceBar: some View {
        Toggle(L("app.general.useIceBar"), isOn: $settings.useIceBar)
            .dragonAnnotation { Text(L("app.general.useIceBar.note")) }
            .disabled(settings.autoEnableIceBar)
    }

    @ViewBuilder
    private var autoEnableIceBar: some View {
        Toggle(isOn: $settings.autoEnableIceBar) {
            HStack {
                Text(L("app.general.autoEnableIceBar"))
                BetaBadge()
            }
        }
        .dragonAnnotation { Text(L("app.general.autoEnableIceBar.note")) }
    }

    @ViewBuilder
    private var iceBarAutoEnableModePicker: some View {
        IcePicker(L("app.general.autoEnableWhen"), selection: $settings.iceBarAutoEnableMode) {
            ForEach(IceBarAutoEnableMode.allCases) { mode in
                Text(mode.localized).tag(mode)
            }
        }
        .dragonAnnotation {
            switch settings.iceBarAutoEnableMode {
            case .screenWidth:
                Text(L("app.general.autoEnable.screenWidth.note"))
            case .screensWithNotch:
                Text(L("app.general.autoEnable.notch.note"))
            }
        }
    }

    @ViewBuilder
    private var iceBarDisplayWidthThreshold: some View {
        LabeledContent {
            TextField(
                L("app.general.width"),
                value: $settings.iceBarDisplayWidthThreshold,
                format: .number.grouping(.never)
            )
            .textFieldStyle(.roundedBorder)
            .frame(width: 80)
        } label: {
            Text(L("app.general.widthThreshold"))
        }
        .dragonAnnotation { Text(L("app.general.widthThreshold.note")) }
    }

    @ViewBuilder
    private var iceBarLocationPicker: some View {
        IcePicker(L("app.general.location"), selection: $settings.iceBarLocation) {
            ForEach(IceBarLocation.allCases) { location in
                Text(location.localized).tag(location)
            }
        }
        .dragonAnnotation {
            switch settings.iceBarLocation {
            case .dynamic:
                Text(L("app.general.location.dynamic.note"))
            case .mousePointer:
                Text(L("app.general.location.mousePointer.note"))
            case .iceIcon:
                Text(L("app.general.location.iceIcon.note"))
            }
        }
    }

    // MARK: Show Options

    @ViewBuilder
    private var showOptions: some View {
        Toggle(L("app.general.showOnClick"), isOn: $settings.showOnClick)
            .dragonAnnotation { Text(L("app.general.showOnClick.note")) }

        Toggle(L("app.general.showOnHover"), isOn: showOnHover)
            .dragonAnnotation { Text(L("app.general.showOnHover.note")) }
        if showOnHover.wrappedValue {
            IceSlider(
                formattedSeconds(hoverDelay.wrappedValue),
                value: hoverDelay,
                in: 0...1,
                step: 0.1
            )
            .dragonAnnotation { Text(L("app.general.hoverDelay.note")) }
        }

        Toggle(L("app.general.showOnScroll"), isOn: $settings.showOnScroll)
            .dragonAnnotation { Text(L("app.general.showOnScroll.note")) }
    }

    // MARK: Rehide Options

    @ViewBuilder
    private var rehideOptions: some View {
        autoRehide
        if settings.autoRehide {
            rehideStrategyPicker
        }
    }

    @ViewBuilder
    private var autoRehide: some View {
        Toggle(L("app.general.autoRehide"), isOn: $settings.autoRehide)
    }

    @ViewBuilder
    private var rehideStrategyPicker: some View {
        VStack {
            IcePicker(L("app.general.strategy"), selection: $settings.rehideStrategy) {
                ForEach(RehideStrategy.allCases) { strategy in
                    Text(strategy.localized).tag(strategy)
                }
            }
            .dragonAnnotation {
                switch settings.rehideStrategy {
                case .smart:
                    Text(L("app.general.strategy.smart.note"))
                case .timed:
                    Text(L("app.general.strategy.timed.note"))
                case .focusedApp:
                    Text(L("app.general.strategy.focusedApp.note"))
                }
            }

            if case .timed = settings.rehideStrategy {
                IceSlider(
                    formattedSeconds(settings.rehideInterval),
                    value: $settings.rehideInterval,
                    in: 0...30,
                    step: 1
                )
            }
        }
    }

    // MARK: Spacing Options

    @ViewBuilder
    private var spacingOptions: some View {
        LabeledContent {
            IceSlider(
                itemSpacingOffsetLabel,
                value: $tempItemSpacingOffset,
                in: -16...16,
                step: 2
            )
            .disabled(isApplyingItemSpacingOffset)
        } label: {
            LabeledContent {
                Button(L("app.general.apply")) {
                    applyTempItemSpacingOffset()
                }
                .help(L("app.general.apply.help"))
                .disabled(isApplyingItemSpacingOffset || tempItemSpacingOffset == settings.itemSpacingOffset)

                if isApplyingItemSpacingOffset {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.5)
                        .frame(width: 15, height: 15)
                } else {
                    Button {
                        tempItemSpacingOffset = 0
                        applyTempItemSpacingOffset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .help(L("app.general.resetSpacing.help"))
                    .disabled(isApplyingItemSpacingOffset || settings.itemSpacingOffset == 0)
                }
            } label: {
                HStack {
                    Text(L("app.general.itemSpacing"))
                    BetaBadge()
                }
            }
        }
        .dragonAnnotation(spacing: 2) {
            Text(L("app.general.itemSpacing.note"))
        }
        .dragonAnnotation(spacing: 10) {
            CalloutBox(
                L("app.general.itemSpacing.callout"),
                systemImage: "exclamationmark.circle"
            )
        }
        .onAppear {
            tempItemSpacingOffset = settings.itemSpacingOffset
        }
    }

    private func applyTempItemSpacingOffset() {
        isApplyingItemSpacingOffset = true
        settings.itemSpacingOffset = tempItemSpacingOffset
        Task {
            do {
                try await appState.spacingManager.applyOffset()
            } catch {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
            isApplyingItemSpacingOffset = false
        }
    }
}
