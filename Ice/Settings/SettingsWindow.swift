//
//  SettingsWindow.swift
//  Ice
//

import Combine
import SwiftUI

// MARK: - SettingsWindow

struct SettingsWindow: Scene {
    @ObservedObject var appState: AppState
    @StateObject private var model = SettingsWindowModel()

    var body: some Scene {
        IceWindow(id: .settings) {
            SettingsView(navigationState: appState.navigationState)
                .onWindowChange { window in
                    model.observeWindowToolbar(window)
                }
                .frame(minWidth: 825, maxWidth: 1150, minHeight: 500, maxHeight: 750)
        }
        .commandsRemoved()
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 625)
        .environmentObject(appState)
    }
}

// MARK: - SettingsWindowModel

@MainActor
private final class SettingsWindowModel: ObservableObject {
    /// Storage for internal observers.
    private var cancellables = Set<AnyCancellable>()

    /// Configures observers for the window's toolbar.
    func observeWindowToolbar(_ window: NSWindow?) {
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables.removeAll()

        guard let window else {
            return
        }

        // SwiftUI seems to create a new toolbar each time the window is opened, so
        // we're using KVO to make sure the values stay set.
        //
        // - FOR FUTURE REFERENCE: Add `.windowToolbarLabelStyle(fixed: .iconOnly)`
        //   to the body of `SettingsWindow` and remove this publisher.
        Publishers.CombineLatest3(
            window.publisher(for: \.toolbar),
            window.publisher(for: \.toolbar?.displayMode),
            window.publisher(for: \.toolbar?.allowsDisplayModeCustomization)
        )
        .sink { toolbar, _, _ in
            toolbar?.displayMode = .iconOnly
            toolbar?.allowsDisplayModeCustomization = false
        }
        .store(in: &cancellables)
    }
}
