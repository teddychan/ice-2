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

    private var itemSpacingOffsetKey: LocalizedStringKey {
        switch tempItemSpacingOffset {
        case -16: "none"
        case 0: "default"
        case 16: "max"
        default: LocalizedStringKey(tempItemSpacingOffset.formatted())
        }
    }

    private var rehideIntervalKey: LocalizedStringKey {
        let formatted = settings.rehideInterval.formatted()
        if settings.rehideInterval == 1 {
            return LocalizedStringKey("\(formatted) second")
        } else {
            return LocalizedStringKey("\(formatted) seconds")
        }
    }

    var body: some View {
        DragonForm {
            DragonSection {
                appOptions
                iceIconOptions
            }
            DragonSection("Show Hidden Items") {
                showOptions
            }
            DragonSection("Rehide") {
                rehideOptions
            }
            DragonSection("Ice 2 Bar") {
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
    @ViewBuilder
    private var appOptions: some View {
        Toggle("Launch at login", isOn: Binding(
            get: { launchesAtLogin },
            set: { newValue in
                LoginItem.setEnabled(newValue)
                // Read the status back: registration can fail, and the toggle should show
                // what the OS actually did rather than what was asked for.
                launchesAtLogin = LoginItem.isEnabled
            }
        ))
        .onAppear { launchesAtLogin = LoginItem.isEnabled }

        languagePicker
    }

    // MARK: Language Options

    /// Lets the user choose the interface language. "Automatic" follows the system language
    /// (English unless the system is set to a language the app ships strings for). Changing the
    /// selection persists it through DragonKit's ``LocalizationManager`` and restarts the app so
    /// both the app's own SwiftUI strings and DragonKit's panes switch together.
    @ViewBuilder
    private var languagePicker: some View {
        Picker("Language", selection: Binding(
            get: { LocalizationManager.shared.language },
            set: { newValue in
                LocalizationManager.shared.setLanguage(newValue)
                // The app's SwiftUI strings resolve through the bundle's preferred
                // localizations, so mirror the choice into AppleLanguages and relaunch.
                if let code = newValue.localeCode {
                    UserDefaults.standard.set([code], forKey: "AppleLanguages")
                } else {
                    UserDefaults.standard.removeObject(forKey: "AppleLanguages")
                }
                appState.relaunch()
            }
        )) {
            Text("Automatic").tag(DragonLanguage.system)
            Text("English").tag(DragonLanguage.en)
            Text("简体中文").tag(DragonLanguage.zhHans)
        }
    }

    // MARK: Ice Icon Options

    @ViewBuilder
    private var iceIconOptions: some View {
        Toggle("Show Ice 2 icon", isOn: $settings.showIceIcon)
            .dragonAnnotation("Click to show hidden menu bar items. Right-click to access Ice 2's settings. Customize the icon in the Appearance settings.")
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
            Text("Automatic Ice 2 Bar")
        }
    }

    // MARK: Advanced Options

    @ViewBuilder
    private var advancedOptions: some View {
        DisclosureGroup {
            spacingOptions
        } label: {
            Text("Advanced")
        }
    }

    @ViewBuilder
    private var useIceBar: some View {
        Toggle("Use Ice 2 Bar", isOn: $settings.useIceBar)
            .dragonAnnotation("Show hidden menu bar items in a separate bar below the menu bar.")
            .disabled(settings.autoEnableIceBar)
    }

    @ViewBuilder
    private var autoEnableIceBar: some View {
        Toggle(isOn: $settings.autoEnableIceBar) {
            HStack {
                Text("Auto-enable Ice 2 Bar")
                BetaBadge()
            }
        }
        .dragonAnnotation("Automatically enable or disable Ice 2 Bar based on the current display.")
    }

    @ViewBuilder
    private var iceBarAutoEnableModePicker: some View {
        IcePicker("Auto-enable when", selection: $settings.iceBarAutoEnableMode) {
            ForEach(IceBarAutoEnableMode.allCases) { mode in
                Text(mode.localized).tag(mode)
            }
        }
        .dragonAnnotation {
            switch settings.iceBarAutoEnableMode {
            case .screenWidth:
                Text("Enable Ice 2 Bar when the active menu bar screen is narrower than the threshold.")
            case .screensWithNotch:
                Text("Enable Ice 2 Bar when the active menu bar screen has a notch.")
            }
        }
    }

    @ViewBuilder
    private var iceBarDisplayWidthThreshold: some View {
        LabeledContent {
            TextField(
                "Width",
                value: $settings.iceBarDisplayWidthThreshold,
                format: .number.grouping(.never)
            )
            .textFieldStyle(.roundedBorder)
            .frame(width: 80)
        } label: {
            Text("Width threshold")
        }
        .dragonAnnotation("Ice 2 Bar will be enabled when the active menu bar screen is narrower than this width in points.")
    }

    @ViewBuilder
    private var iceBarLocationPicker: some View {
        IcePicker("Location", selection: $settings.iceBarLocation) {
            ForEach(IceBarLocation.allCases) { location in
                Text(location.localized).tag(location)
            }
        }
        .dragonAnnotation {
            switch settings.iceBarLocation {
            case .dynamic:
                Text("The Ice 2 Bar's location changes based on context.")
            case .mousePointer:
                Text("The Ice 2 Bar is centered below the mouse pointer.")
            case .iceIcon:
                Text("The Ice 2 Bar is centered below the Ice 2 icon.")
            }
        }
    }

    // MARK: Show Options

    private func formattedToSeconds(_ interval: TimeInterval) -> LocalizedStringKey {
        let formatted = interval.formatted()
        return if interval == 1 {
            LocalizedStringKey(formatted + " second")
        } else {
            LocalizedStringKey(formatted + " seconds")
        }
    }

    @ViewBuilder
    private var showOptions: some View {
        Toggle("Show on click", isOn: $settings.showOnClick)
            .dragonAnnotation("Click inside an empty area of the menu bar to show hidden menu bar items.")

        Toggle("Show on hover", isOn: showOnHover)
            .dragonAnnotation("Hover over an empty area of the menu bar or the Ice 2 icon to show hidden menu bar items.")
        if showOnHover.wrappedValue {
            IceSlider(
                formattedToSeconds(hoverDelay.wrappedValue),
                value: hoverDelay,
                in: 0...1,
                step: 0.1
            )
            .dragonAnnotation("The amount of time to wait before showing hidden items.")
        }

        Toggle("Show on scroll", isOn: $settings.showOnScroll)
            .dragonAnnotation("Scroll or swipe in the menu bar to show hidden menu bar items.")
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
        Toggle("Automatically rehide", isOn: $settings.autoRehide)
    }

    @ViewBuilder
    private var rehideStrategyPicker: some View {
        VStack {
            IcePicker("Strategy", selection: $settings.rehideStrategy) {
                ForEach(RehideStrategy.allCases) { strategy in
                    Text(strategy.localized).tag(strategy)
                }
            }
            .dragonAnnotation {
                switch settings.rehideStrategy {
                case .smart:
                    Text("Menu bar items are rehidden using a smart algorithm.")
                case .timed:
                    Text("Menu bar items are rehidden after a fixed amount of time.")
                case .focusedApp:
                    Text("Menu bar items are rehidden when the focused app changes.")
                }
            }

            if case .timed = settings.rehideStrategy {
                IceSlider(
                    rehideIntervalKey,
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
                itemSpacingOffsetKey,
                value: $tempItemSpacingOffset,
                in: -16...16,
                step: 2
            )
            .disabled(isApplyingItemSpacingOffset)
        } label: {
            LabeledContent {
                Button("Apply") {
                    applyTempItemSpacingOffset()
                }
                .help("Apply the current spacing")
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
                    .help("Reset to the default spacing")
                    .disabled(isApplyingItemSpacingOffset || settings.itemSpacingOffset == 0)
                }
            } label: {
                HStack {
                    Text("Menu bar item spacing")
                    BetaBadge()
                }
            }
        }
        .dragonAnnotation(
            "Applying this setting will relaunch all apps with menu bar items. Some apps may need to be manually relaunched.",
            spacing: 2
        )
        .dragonAnnotation(spacing: 10) {
            CalloutBox(
                "Note: You may need to log out and back in for this setting to apply properly.",
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
