//
//  MenuBarLayoutSettingsPane.swift
//  Ice
//

import DragonKit
import SwiftUI

struct MenuBarLayoutSettingsPane: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var itemManager: MenuBarItemManager
    @ObservedObject var profileSettings: MenuBarLayoutProfilesSettings
    @ObservedObject var spacerManager: MenuBarSpacerManager
    @State private var newProfileName = ""
    @State private var applyingProfileID: MenuBarLayoutProfile.ID?
    @State private var isCapturingLayout = false
    @State private var isPresentingError = false
    @State private var presentedError: LocalizedErrorWrapper?

    private var hasItems: Bool {
        !itemManager.itemCache.managedItems.isEmpty
    }

    private var isLoadingItems: Bool {
        !itemManager.hasCompletedInitialCache
    }

    var body: some View {
        if !ScreenCapture.cachedCheckPermissions() {
            missingScreenRecordingPermissions
        } else if appState.menuBarManager.isMenuBarHiddenBySystemUserDefaults {
            cannotArrange
        } else {
            DragonForm {
                header
                profiles
                spacers
                layoutBars
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        DragonSection {
            VStack(spacing: 3) {
                Text(L("app.layout.header.title"))
                    .font(.title3.bold())
                Text(L("app.layout.header.subtitle"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(15)
        }
    }

    @ViewBuilder
    private var layoutBars: some View {
        VStack(spacing: 20) {
            ForEach(MenuBarSection.Name.allCases, id: \.self) { section in
                layoutBar(for: section)
            }
        }
        .opacity(hasItems ? 1 : 0.75)
        .blur(radius: hasItems ? 0 : 5)
        .allowsHitTesting(hasItems)
        .overlay {
            if !hasItems {
                if isLoadingItems {
                    loadingMenuBarItems
                } else {
                    noMenuBarItems
                }
            }
        }
    }

    @ViewBuilder
    private var profiles: some View {
        DragonSection {
            Text(L("app.layout.section.profiles"))
        } content: {
            profileCreationRow

            if profileSettings.profiles.isEmpty {
                Text(L("app.layout.noProfiles"))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(profileSettings.profiles) { profile in
                    profileRow(profile)
                }
            }
        }
        .alert(isPresented: $isPresentingError, error: presentedError) {
            Button(L("DragonKit.ok")) {
                presentedError = nil
                isPresentingError = false
            }
        }
    }

    @ViewBuilder
    private var profileCreationRow: some View {
        HStack {
            TextField(L("app.layout.profileName"), text: $newProfileName)

            Button(L("app.layout.saveCurrent")) {
                saveCurrentLayout()
            }
            .disabled(!hasItems || isCapturingLayout)
        }
    }

    private func saveCurrentLayout() {
        let name = newProfileName
        newProfileName = ""
        isCapturingLayout = true
        Task {
            defer { isCapturingLayout = false }
            await profileSettings.createProfile(named: name)
        }
    }

    @ViewBuilder
    private func profileRow(_ profile: MenuBarLayoutProfile) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)

                Text(profileSummary(profile))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if applyingProfileID == profile.id {
                ProgressView()
                    .controlSize(.small)
            }

            Button(L("app.common.apply")) {
                applyProfile(profile)
            }
            .disabled(applyingProfileID != nil || isCapturingLayout)

            Button(L("app.layout.updateProfile")) {
                updateProfile(profile)
            }
            .disabled(!hasItems || applyingProfileID != nil || isCapturingLayout)

            Button(L("app.common.delete"), role: .destructive) {
                profileSettings.deleteProfile(profile)
            }
            .disabled(applyingProfileID != nil || isCapturingLayout)
        }
    }

    private func updateProfile(_ profile: MenuBarLayoutProfile) {
        isCapturingLayout = true
        Task {
            defer { isCapturingLayout = false }
            await profileSettings.updateProfile(profile)
        }
    }

    private func profileSummary(_ profile: MenuBarLayoutProfile) -> String {
        String(
            format: L("app.layout.profileSummary"),
            profile.itemCount(for: .visible),
            profile.itemCount(for: .hidden),
            profile.itemCount(for: .alwaysHidden)
        )
    }

    private func applyProfile(_ profile: MenuBarLayoutProfile) {
        applyingProfileID = profile.id
        Task {
            defer {
                applyingProfileID = nil
            }
            do {
                try await profileSettings.applyProfile(profile)
            } catch {
                presentedError = LocalizedErrorWrapper(error)
                isPresentingError = true
            }
        }
    }

    @ViewBuilder
    private var spacers: some View {
        DragonSection {
            Text(L("app.layout.section.spacers"))
        } content: {
            HStack {
                Text(L("app.layout.spacers.note"))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(L("app.layout.addSpacer")) {
                    spacerManager.createSpacer()
                }
            }

            ForEach(spacerManager.spacers) { spacer in
                spacerRow(spacer)
            }
        }
    }

    @ViewBuilder
    private func spacerRow(_ spacer: MenuBarSpacer) -> some View {
        HStack {
            Text(spacer.name)

            Slider(
                value: Binding(
                    get: { spacer.width },
                    set: { spacerManager.setWidth($0, for: spacer) }
                ),
                in: 8...80,
                step: 1
            )

            Text(String(format: L("app.layout.points"), Int(spacer.width)))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .trailing)

            Button(L("app.common.delete"), role: .destructive) {
                spacerManager.deleteSpacer(spacer)
            }
        }
    }

    @ViewBuilder
    private var cannotArrange: some View {
        Text(L("app.layout.cannotArrange"))
            .font(.title3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var missingScreenRecordingPermissions: some View {
        VStack {
            Text(L("app.layout.needsScreenRecording"))
                .font(.title2)

            Text(L("app.layout.needsScreenRecording.note"))
                .foregroundStyle(.secondary)

            HStack {
                Button {
                    appState.navigationState.settingsNavigationIdentifier = .advanced
                } label: {
                    Text(L("app.layout.goToAdvanced"))
                }
                .buttonStyle(.link)

                Button(L("app.common.relaunch")) {
                    appState.relaunch()
                }
            }
        }
    }

    @ViewBuilder
    private var loadingMenuBarItems: some View {
        VStack {
            Text(L("app.common.loadingItems"))
            ProgressView()
        }
        .font(.title)
    }

    @ViewBuilder
    private var noMenuBarItems: some View {
        VStack(spacing: 8) {
            Text(L("app.layout.noItems"))

            HStack {
                Button(L("app.common.checkAgain")) {
                    Task {
                        await itemManager.cacheItemsRegardless()
                    }
                }

                Button(L("app.layout.restoreIceIcon")) {
                    restoreIceIcon()
                }
            }
        }
        .font(.title3)
    }

    private func restoreIceIcon() {
        appState.settings.general.showIceIcon = false
        appState.settings.general.showIceIcon = true

        Task {
            await itemManager.cacheItemsRegardless()
        }
    }

    @ViewBuilder
    private func layoutBar(for name: MenuBarSection.Name) -> some View {
        if
            let section = appState.menuBarManager.section(withName: name),
            section.isEnabled
        {
            VStack(alignment: .leading) {
                Text(name.localized)
                    .font(.headline)
                    .padding(.leading, 8)

                LayoutBar(imageCache: appState.imageCache, section: name)
            }
        }
    }
}
