//
//  MenuBarTriggerSettings.swift
//  Ice
//

import AppKit
import Combine
import Foundation
import OSLog

enum MenuBarTriggerTarget: Hashable {
    case hiddenSection
    case itemGroup(UUID)
}

struct MenuBarTrigger: Codable, Hashable, Identifiable {
    enum Condition: Codable, Hashable {
        case frontmostApplication(bundleIdentifier: String)
    }

    enum Action: String, Codable, Hashable {
        case showHiddenSection
        case temporarilyShowItemGroup
    }

    var id: UUID
    var name: String
    var createdAt: Date
    var condition: Condition
    var action: Action
    var itemGroupID: MenuBarItemGroup.ID?

    var bundleIdentifier: String? {
        switch condition {
        case .frontmostApplication(let bundleIdentifier):
            bundleIdentifier
        }
    }

    func matches(frontmostBundleIdentifier bundleIdentifier: String) -> Bool {
        switch condition {
        case .frontmostApplication(let expected):
            expected == bundleIdentifier
        }
    }
}

@MainActor
final class MenuBarTriggerSettings: ObservableObject {
    @Published private(set) var triggers = [MenuBarTrigger]()
    @Published private(set) var candidateApplicationName: String?

    private struct ApplicationCandidate {
        var bundleIdentifier: String
        var name: String
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var candidateApplication: ApplicationCandidate?
    private var cancellables = Set<AnyCancellable>()
    private weak var appState: AppState?

    func performSetup(with appState: AppState) {
        self.appState = appState
        loadInitialState()
        updateCandidate(with: NSWorkspace.shared.frontmostApplication)
        configureCancellables()
    }

    @discardableResult
    func createFrontmostApplicationTrigger(target: MenuBarTriggerTarget) -> Bool {
        guard let candidateApplication else {
            return false
        }

        let (action, itemGroupID): (MenuBarTrigger.Action, MenuBarItemGroup.ID?) = switch target {
        case .hiddenSection:
            (.showHiddenSection, nil)
        case .itemGroup(let id):
            (.temporarilyShowItemGroup, id)
        }

        let trigger = MenuBarTrigger(
            id: UUID(),
            name: candidateApplication.name,
            createdAt: Date(),
            condition: .frontmostApplication(bundleIdentifier: candidateApplication.bundleIdentifier),
            action: action,
            itemGroupID: itemGroupID
        )

        guard !triggers.contains(where: {
            $0.condition == trigger.condition &&
                $0.action == trigger.action &&
                $0.itemGroupID == trigger.itemGroupID
        }) else {
            return false
        }

        triggers.append(trigger)
        performTriggers(for: NSWorkspace.shared.frontmostApplication)
        return true
    }

    func deleteTrigger(_ trigger: MenuBarTrigger) {
        triggers.removeAll { $0.id == trigger.id }
    }

    private func loadInitialState() {
        guard let data = Defaults.data(forKey: .menuBarTriggers) else {
            return
        }
        do {
            triggers = try decoder.decode([MenuBarTrigger].self, from: data)
        } catch {
            Logger.serialization.error("Error decoding menu bar triggers: \(error, privacy: .public)")
        }
    }

    private func configureCancellables() {
        $triggers
            .encode(encoder: encoder)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    Logger.serialization.error("Error encoding menu bar triggers: \(error, privacy: .public)")
                }
            } receiveValue: { data in
                Defaults.set(data, forKey: .menuBarTriggers)
            }
            .store(in: &cancellables)

        NSWorkspace.shared.publisher(for: \.frontmostApplication)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] app in
                guard let self else {
                    return
                }
                updateCandidate(with: app)
                performTriggers(for: app)
            }
            .store(in: &cancellables)
    }

    private func updateCandidate(with app: NSRunningApplication?) {
        guard
            let app,
            app.bundleIdentifier != Constants.bundleIdentifier,
            let bundleIdentifier = app.bundleIdentifier
        else {
            return
        }

        let name = app.localizedName ?? bundleIdentifier
        candidateApplication = ApplicationCandidate(
            bundleIdentifier: bundleIdentifier,
            name: name
        )
        candidateApplicationName = name
    }

    private func performTriggers(for app: NSRunningApplication?) {
        guard
            let appState,
            let bundleIdentifier = app?.bundleIdentifier,
            bundleIdentifier != Constants.bundleIdentifier
        else {
            return
        }

        for trigger in triggers where trigger.matches(frontmostBundleIdentifier: bundleIdentifier) {
            switch trigger.action {
            case .showHiddenSection:
                appState.menuBarManager.section(withName: .hidden)?.show()
            case .temporarilyShowItemGroup:
                guard
                    let id = trigger.itemGroupID,
                    let group = appState.settings.layoutProfiles.groups.first(where: { $0.id == id })
                else {
                    continue
                }
                Task {
                    await appState.settings.layoutProfiles.temporarilyShowGroup(group)
                }
            }
        }
    }
}
