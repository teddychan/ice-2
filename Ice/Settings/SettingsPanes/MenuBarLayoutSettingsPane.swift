//
//  MenuBarLayoutSettingsPane.swift
//  Ice
//

import SwiftUI

struct MenuBarLayoutSettingsPane: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var itemManager: MenuBarItemManager
    @ObservedObject var profileSettings: MenuBarLayoutProfilesSettings
    @ObservedObject var spacerManager: MenuBarSpacerManager
    @State private var newProfileName = ""
    @State private var newGroupName = ""
    @State private var applyingProfileID: MenuBarLayoutProfile.ID?
    @State private var showingGroupID: MenuBarItemGroup.ID?
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
            IceForm(spacing: 20) {
                header
                profiles
                groups
                spacers
                layoutBars
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        IceSection {
            VStack(spacing: 3) {
                Text("Drag to arrange your menu bar items into different sections.")
                    .font(.title3.bold())
                Text("Items can also be arranged by ⌘ Command + dragging them in the menu bar.")
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
        IceSection("Profiles") {
            profileCreationRow

            if profileSettings.profiles.isEmpty {
                Text("No saved layout profiles.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(profileSettings.profiles) { profile in
                    profileRow(profile)
                }
            }
        }
        .alert(isPresented: $isPresentingError, error: presentedError) {
            Button("OK") {
                presentedError = nil
                isPresentingError = false
            }
        }
    }

    @ViewBuilder
    private var profileCreationRow: some View {
        HStack {
            TextField("Profile name", text: $newProfileName)

            Button("Save Current Layout") {
                profileSettings.createProfile(named: newProfileName)
                newProfileName = ""
            }
            .disabled(!hasItems)
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

            Button("Apply") {
                applyProfile(profile)
            }
            .disabled(applyingProfileID != nil)

            Button("Update") {
                profileSettings.updateProfile(profile)
            }
            .disabled(!hasItems || applyingProfileID != nil)

            Button("Delete", role: .destructive) {
                profileSettings.deleteProfile(profile)
            }
            .disabled(applyingProfileID != nil)
        }
    }

    private func profileSummary(_ profile: MenuBarLayoutProfile) -> LocalizedStringKey {
        let visibleCount = profile.itemCount(for: .visible)
        let hiddenCount = profile.itemCount(for: .hidden)
        let alwaysHiddenCount = profile.itemCount(for: .alwaysHidden)
        return "\(visibleCount) visible, \(hiddenCount) hidden, \(alwaysHiddenCount) always-hidden"
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
    private var groups: some View {
        IceSection("Groups") {
            HStack {
                TextField("Group name", text: $newGroupName)

                Button("Save Hidden Items") {
                    profileSettings.createGroup(named: newGroupName)
                    newGroupName = ""
                }
                .disabled(!hasItems)
            }

            if profileSettings.groups.isEmpty {
                Text("No saved item groups.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(profileSettings.groups) { group in
                    groupRow(group)
                }
            }
        }
    }

    @ViewBuilder
    private func groupRow(_ group: MenuBarItemGroup) -> some View {
        let availableCount = availableHiddenItemCount(for: group)

        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)

                Text(groupSummary(group, availableCount: availableCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if showingGroupID == group.id {
                ProgressView()
                    .controlSize(.small)
            }

            Button("Show") {
                temporarilyShowGroup(group)
            }
            .disabled(availableCount == 0 || showingGroupID != nil)

            Button("Delete", role: .destructive) {
                profileSettings.deleteGroup(group)
            }
            .disabled(showingGroupID != nil)
        }
    }

    private func groupSummary(
        _ group: MenuBarItemGroup,
        availableCount: Int
    ) -> LocalizedStringKey {
        "\(group.itemCount) saved, \(availableCount) available to show"
    }

    private func availableHiddenItemCount(for group: MenuBarItemGroup) -> Int {
        let tags = Set(group.itemTags)
        let items = (
            itemManager.itemCache.managedItems(for: .hidden) +
            itemManager.itemCache.managedItems(for: .alwaysHidden)
        )
        return items.filter { tags.contains($0.tag) }.count
    }

    private func temporarilyShowGroup(_ group: MenuBarItemGroup) {
        showingGroupID = group.id
        Task {
            defer {
                showingGroupID = nil
            }
            _ = await profileSettings.temporarilyShowGroup(group)
        }
    }

    @ViewBuilder
    private var spacers: some View {
        IceSection("Spacers") {
            HStack {
                Text("Add flexible space between menu bar items.")
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Add Spacer") {
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

            Text("\(Int(spacer.width)) pt")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .trailing)

            Button("Delete", role: .destructive) {
                spacerManager.deleteSpacer(spacer)
            }
        }
    }

    @ViewBuilder
    private var cannotArrange: some View {
        Text("Ice 2 cannot arrange menu bar items in automatically hidden menu bars.")
            .font(.title3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var missingScreenRecordingPermissions: some View {
        VStack {
            Text("Menu bar layout requires screen recording permissions.")
                .font(.title2)

            Text("On macOS 26, Ice 2 may need to relaunch after you grant this permission.")
                .foregroundStyle(.secondary)

            HStack {
                Button {
                    appState.navigationState.settingsNavigationIdentifier = .advanced
                } label: {
                    Text("Go to Advanced Settings")
                }
                .buttonStyle(.link)

                Button("Relaunch Ice 2") {
                    appState.relaunch()
                }
            }
        }
    }

    @ViewBuilder
    private var loadingMenuBarItems: some View {
        VStack {
            Text("Loading menu bar items…")
            ProgressView()
        }
        .font(.title)
    }

    @ViewBuilder
    private var noMenuBarItems: some View {
        VStack(spacing: 8) {
            Text("No manageable menu bar items found.")

            HStack {
                Button("Check Again") {
                    Task {
                        await itemManager.cacheItemsRegardless()
                    }
                }

                Button("Restore Ice 2 Icon") {
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
