//
//  MenuBarSpacerManager.swift
//  Ice
//

import Cocoa
import Combine
import OSLog

struct MenuBarSpacer: Codable, Hashable, Identifiable {
    static let autosaveNamePrefix = "Ice.Spacer."

    var id: UUID
    var name: String
    var width: Double

    var autosaveName: String {
        Self.autosaveNamePrefix + id.uuidString
    }
}

@MainActor
final class MenuBarSpacerManager: ObservableObject {
    @Published private(set) var spacers = [MenuBarSpacer]()

    @MainActor
    private final class SpacerStatusItem {
        let statusItem: NSStatusItem

        init(spacer: MenuBarSpacer) {
            self.statusItem = NSStatusBar.system.statusItem(withLength: spacer.width)
            self.statusItem.autosaveName = spacer.autosaveName
            update(with: spacer)
        }

        deinit {
            NSStatusBar.system.removeStatusItem(statusItem)
        }

        func update(with spacer: MenuBarSpacer) {
            statusItem.length = spacer.width
            statusItem.button?.title = ""
            statusItem.button?.image = nil
            statusItem.button?.toolTip = spacer.name
        }
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var storage = [MenuBarSpacer.ID: SpacerStatusItem]()
    private var cancellables = Set<AnyCancellable>()
    private weak var appState: AppState?

    func performSetup(with appState: AppState) {
        self.appState = appState
        loadInitialState()
        syncStatusItems()
        configureCancellables()
    }

    func createSpacer() {
        let spacer = MenuBarSpacer(
            id: UUID(),
            name: "Spacer \(spacers.count + 1)",
            width: 24
        )
        spacers.append(spacer)
    }

    func deleteSpacer(_ spacer: MenuBarSpacer) {
        spacers.removeAll { $0.id == spacer.id }
    }

    func setWidth(_ width: Double, for spacer: MenuBarSpacer) {
        guard let index = spacers.firstIndex(where: { $0.id == spacer.id }) else {
            return
        }
        spacers[index].width = width.clamped(min: 8, max: 80)
    }

    private func loadInitialState() {
        guard let data = Defaults.data(forKey: .menuBarSpacers) else {
            return
        }
        do {
            spacers = try decoder.decode([MenuBarSpacer].self, from: data)
        } catch {
            Logger.serialization.error("Error decoding menu bar spacers: \(error, privacy: .public)")
        }
    }

    private func configureCancellables() {
        $spacers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] spacers in
                guard let self else {
                    return
                }
                syncStatusItems()
                do {
                    let data = try encoder.encode(spacers)
                    Defaults.set(data, forKey: .menuBarSpacers)
                } catch {
                    Logger.serialization.error("Error encoding menu bar spacers: \(error, privacy: .public)")
                }
            }
            .store(in: &cancellables)
    }

    private func syncStatusItems() {
        let currentIDs = Set(spacers.map(\.id))
        for id in storage.keys where !currentIDs.contains(id) {
            storage[id] = nil
        }

        for spacer in spacers {
            if let item = storage[spacer.id] {
                item.update(with: spacer)
            } else {
                storage[spacer.id] = SpacerStatusItem(spacer: spacer)
            }
        }

        Task {
            await appState?.itemManager.cacheItemsRegardless()
        }
    }
}
