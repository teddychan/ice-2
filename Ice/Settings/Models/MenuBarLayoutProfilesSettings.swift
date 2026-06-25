//
//  MenuBarLayoutProfilesSettings.swift
//  Ice
//

import Combine
import Foundation
import OSLog

struct MenuBarLayoutProfile: Codable, Hashable, Identifiable {
    struct SectionSnapshot: Codable, Hashable {
        var section: MenuBarSection.Name
        var itemTags: [MenuBarItemTag]
    }

    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var sections: [SectionSnapshot]

    func itemTags(for section: MenuBarSection.Name) -> [MenuBarItemTag] {
        sections.first { $0.section == section }?.itemTags ?? []
    }

    func itemCount(for section: MenuBarSection.Name) -> Int {
        itemTags(for: section).count
    }
}

struct MenuBarItemGroup: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var itemTags: [MenuBarItemTag]

    var itemCount: Int {
        itemTags.count
    }
}

@MainActor
final class MenuBarLayoutProfilesSettings: ObservableObject {
    @Published private(set) var profiles = [MenuBarLayoutProfile]()
    @Published private(set) var groups = [MenuBarItemGroup]()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var cancellables = Set<AnyCancellable>()

    private(set) weak var appState: AppState?

    func performSetup(with appState: AppState) {
        self.appState = appState
        loadInitialState()
        configureCancellables()
    }

    private func loadInitialState() {
        guard let data = Defaults.data(forKey: .menuBarLayoutProfiles) else {
            loadInitialGroups()
            return
        }
        do {
            profiles = try decoder.decode([MenuBarLayoutProfile].self, from: data)
        } catch {
            Logger.serialization.error("Error decoding menu bar layout profiles: \(error, privacy: .public)")
        }
        loadInitialGroups()
    }

    private func loadInitialGroups() {
        guard let data = Defaults.data(forKey: .menuBarItemGroups) else {
            return
        }
        do {
            groups = try decoder.decode([MenuBarItemGroup].self, from: data)
        } catch {
            Logger.serialization.error("Error decoding menu bar item groups: \(error, privacy: .public)")
        }
    }

    private func configureCancellables() {
        $profiles
            .encode(encoder: encoder)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    Logger.serialization.error("Error encoding menu bar layout profiles: \(error, privacy: .public)")
                }
            } receiveValue: { data in
                Defaults.set(data, forKey: .menuBarLayoutProfiles)
            }
            .store(in: &cancellables)

        $groups
            .encode(encoder: encoder)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    Logger.serialization.error("Error encoding menu bar item groups: \(error, privacy: .public)")
                }
            } receiveValue: { data in
                Defaults.set(data, forKey: .menuBarItemGroups)
            }
            .store(in: &cancellables)
    }

    func createProfile(named name: String) {
        guard let profile = makeProfile(name: name) else {
            return
        }
        profiles.append(profile)
    }

    func updateProfile(_ profile: MenuBarLayoutProfile) {
        guard
            let index = profiles.firstIndex(where: { $0.id == profile.id }),
            let updatedProfile = makeProfile(
                id: profile.id,
                name: profile.name,
                createdAt: profile.createdAt
            )
        else {
            return
        }
        profiles[index] = updatedProfile
    }

    func deleteProfile(_ profile: MenuBarLayoutProfile) {
        profiles.removeAll { $0.id == profile.id }
    }

    func createGroup(named name: String) {
        guard let group = makeGroup(name: name) else {
            return
        }
        groups.append(group)
    }

    func deleteGroup(_ group: MenuBarItemGroup) {
        groups.removeAll { $0.id == group.id }
    }

    func temporarilyShowGroup(_ group: MenuBarItemGroup) async -> Int {
        guard let appState else {
            return 0
        }
        return await appState.itemManager.temporarilyShowItems(in: group, clickingWith: .left)
    }

    func applyProfile(_ profile: MenuBarLayoutProfile) async throws {
        guard let appState else {
            throw ApplyError.missingAppState
        }
        if
            !appState.settings.advanced.enableAlwaysHiddenSection,
            !profile.itemTags(for: .alwaysHidden).isEmpty
        {
            appState.settings.advanced.enableAlwaysHiddenSection = true
            try? await Task.sleep(for: .milliseconds(250))
        }
        try await appState.itemManager.applyLayoutProfile(profile)
    }

    private func makeProfile(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date()
    ) -> MenuBarLayoutProfile? {
        guard let appState else {
            return nil
        }
        let now = Date()
        let sections = MenuBarSection.Name.allCases.map { section in
            MenuBarLayoutProfile.SectionSnapshot(
                section: section,
                // Exclude Ice's own spacer items: they are positioned by AppKit
                // via their status-item autosave names, not by the layout system,
                // so capturing them would have profile-apply synthetically move
                // them (and surface phantom "Spacer" entries to the user).
                itemTags: appState.itemManager.itemCache.managedItems(for: section)
                    .filter { !$0.isSpacerItem }
                    .map(\.tag)
            )
        }
        return MenuBarLayoutProfile(
            id: id,
            name: normalizedProfileName(name),
            createdAt: createdAt,
            updatedAt: now,
            sections: sections
        )
    }

    private func makeGroup(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date()
    ) -> MenuBarItemGroup? {
        guard let appState else {
            return nil
        }

        let hiddenItems = appState.itemManager.itemCache.managedItems(for: .hidden)
        let alwaysHiddenItems = appState.itemManager.itemCache.managedItems(for: .alwaysHidden)
        var items = hiddenItems + alwaysHiddenItems

        if items.isEmpty {
            items = appState.itemManager.itemCache.managedItems
        }

        let tags = uniqueItemTags(from: items)
        guard !tags.isEmpty else {
            return nil
        }

        let now = Date()
        return MenuBarItemGroup(
            id: id,
            name: normalizedGroupName(name),
            createdAt: createdAt,
            updatedAt: now,
            itemTags: tags
        )
    }

    private func uniqueItemTags(from items: [MenuBarItem]) -> [MenuBarItemTag] {
        var seen = Set<MenuBarItemTag>()
        return items.compactMap { item in
            // Skip control items and Ice's own spacers: item groups are meant to
            // temporarily reveal real third-party items, and clicking a spacer is
            // a no-op that would only pollute the group with phantom entries.
            guard !item.isControlItem, !item.isSpacerItem, !seen.contains(item.tag) else {
                return nil
            }
            seen.insert(item.tag)
            return item.tag
        }
    }

    private func normalizedProfileName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty else {
            return trimmed
        }
        return uniqueDefaultName(prefix: "Layout Profile", existing: profiles.map(\.name))
    }

    private func normalizedGroupName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty else {
            return trimmed
        }
        return uniqueDefaultName(prefix: "Item Group", existing: groups.map(\.name))
    }

    /// Returns "<prefix> N" using the smallest N that is not already taken,
    /// so default names stay unique even after profiles/groups are deleted.
    private func uniqueDefaultName(prefix: String, existing: [String]) -> String {
        let taken = Set(existing)
        var index = 1
        while taken.contains("\(prefix) \(index)") {
            index += 1
        }
        return "\(prefix) \(index)"
    }
}

extension MenuBarLayoutProfilesSettings {
    enum ApplyError: LocalizedError {
        case missingAppState

        var errorDescription: String? {
            switch self {
            case .missingAppState: "Ice is not ready to apply layout profiles."
            }
        }
    }
}
