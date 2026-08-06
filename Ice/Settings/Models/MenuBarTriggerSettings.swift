//
//  MenuBarTriggerSettings.swift
//  Ice
//

import AppKit
import Combine
import Foundation
import OSLog

struct MenuBarTrigger: Codable, Hashable, Identifiable {
    enum Condition: Codable, Hashable {
        case frontmostApplication(bundleIdentifier: String)
    }

    enum Action: String, Codable, Hashable {
        case showHiddenSection
    }

    var id: UUID
    var name: String
    var createdAt: Date
    var condition: Condition
    var action: Action

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
    func createFrontmostApplicationTrigger() -> Bool {
        guard let candidateApplication else {
            return false
        }

        let trigger = MenuBarTrigger(
            id: UUID(),
            name: candidateApplication.name,
            createdAt: Date(),
            condition: .frontmostApplication(bundleIdentifier: candidateApplication.bundleIdentifier),
            action: .showHiddenSection
        )

        guard !triggers.contains(where: {
            $0.condition == trigger.condition && $0.action == trigger.action
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
            triggers = try Self.decodeTriggers(from: data, using: decoder)
        } catch {
            Logger.serialization.error("Error decoding menu bar triggers: \(error, privacy: .public)")
        }
    }

    /// Decodes stored triggers, discarding individually any that this version can
    /// no longer represent.
    ///
    /// ``MenuBarTrigger/Action`` is a raw-value enum, so a trigger written by an
    /// older version with an action that no longer exists — `temporarilyShowItemGroup`,
    /// removed along with item groups — throws when decoded. Decoding the array in one
    /// go would throw on the first such trigger and lose *every* trigger the user had,
    /// including the ones this version still understands. Each element is decoded on its
    /// own so only the obsolete ones are dropped.
    nonisolated static func decodeTriggers(from data: Data, using decoder: JSONDecoder) throws -> [MenuBarTrigger] {
        try decoder.decode([LenientTrigger].self, from: data).compactMap(\.trigger)
    }

    /// Decodes one trigger, yielding `nil` instead of throwing when it is no longer
    /// representable, so one unreadable element cannot fail the whole array.
    private struct LenientTrigger: Decodable {
        let trigger: MenuBarTrigger?

        init(from decoder: any Decoder) throws {
            trigger = try? MenuBarTrigger(from: decoder)
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
            }
        }
    }
}
