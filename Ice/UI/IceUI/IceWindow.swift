//
//  IceWindow.swift
//  Ice
//

import Combine
import SwiftUI

// MARK: - IceWindow

/// A custom scene representing one of Ice's windows.
struct IceWindow<Content: View>: Scene {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    /// The window's identifier.
    let id: IceWindowIdentifier

    /// The window's content view.
    let content: Content

    /// Creates a window with an identifier constant.
    ///
    /// - Parameters:
    ///   - id: A custom identifier constant.
    ///   - content: The content view to display in the window.
    init(id: IceWindowIdentifier, @ViewBuilder content: () -> Content) {
        self.id = id
        self.content = content()
    }

    var body: some Scene {
        windowScene.once {
            // SwiftUI waits to create the underlying NSWindow until the scene
            // is first presented. We may need a valid window reference before
            // that point, so we open the window and immediately dismiss it.
            //
            // - Note: Both actions are called during the same run loop cycle,
            //   so the window isn't actually opened.
            openWindow(id: id)
            dismissWindow(id: id)
        }
    }

    @ViewBuilder
    private var windowContentView: some View {
        // Only render the (potentially expensive) content while the window is
        // actually visible. The window is materialized eagerly above so that a
        // valid reference exists early, but its SwiftUI content would otherwise
        // keep laying itself out on every display cycle while hidden off screen,
        // burning CPU/energy for a window the user isn't looking at.
        WindowVisibilityGate {
            content.onWindowChange { window in
                window?.collectionBehavior.insert(.moveToActiveSpace)
            }
        }
    }

    private var windowScene: some Scene {
        Window(id.titleKey, id: id.rawValue) {
            windowContentView
        }
        .defaultLaunchBehavior(.suppressed)
    }
}

// MARK: - WindowVisibilityGate

/// Renders its content only while the enclosing window is on screen.
///
/// While the window is hidden (e.g. after being materialized early but not yet
/// shown, or after being closed), the content is replaced with an empty view so
/// SwiftUI has nothing to lay out. This prevents a hidden window's view tree
/// from being re-measured on every display cycle, which is a needless drain.
private struct WindowVisibilityGate<Content: View>: View {
    @ViewBuilder let content: Content

    @State private var isVisible = false
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        ZStack {
            if isVisible {
                content
            } else {
                Color.clear.accessibilityHidden(true)
            }
        }
        .onWindowChange { window in
            observe(window)
        }
    }

    /// Observes the given window's visibility and updates ``isVisible``.
    private func observe(_ window: NSWindow?) {
        cancellables.removeAll()

        guard let window else {
            isVisible = false
            return
        }

        func recompute() {
            // An ordered-out or fully occluded window doesn't need its content
            // laid out. `isVisible` is false while the window is ordered out.
            isVisible = window.isVisible && window.occlusionState.contains(.visible)
        }

        window.publisher(for: \.isVisible)
            .sink { _ in recompute() }
            .store(in: &cancellables)
        NotificationCenter.default
            .publisher(for: NSWindow.didChangeOcclusionStateNotification, object: window)
            .sink { _ in recompute() }
            .store(in: &cancellables)

        recompute()
    }
}

// MARK: - IceWindowIdentifier

/// Custom identifier constants uses to create Ice's windows.
enum IceWindowIdentifier: String, Sendable, CustomStringConvertible {
    /// The identifier for Ice's main settings window.
    case settings = "SettingsWindow"

    /// The identifier for Ice's permissions window.
    case permissions = "PermissionsWindow"

    /// The non-localized title of the corresponding window.
    ///
    /// - Note: Use ``titleKey`` to get the localized title.
    var titleString: String {
        switch self {
        case .settings: Constants.displayName
        case .permissions: String(localized: "Permissions")
        }
    }

    /// The localized title of the corresponding window.
    ///
    /// - Note: Use ``titleString`` to get the non-localized title.
    var titleKey: LocalizedStringKey {
        LocalizedStringKey(titleString)
    }

    /// A textual representation of the identifier.
    var description: String {
        rawValue
    }
}

// MARK: - OpenWindowAction

extension OpenWindowAction {
    /// Opens the corresponding window for the given identifier.
    ///
    /// - Parameter id: An identifier for one of Ice's windows.
    func callAsFunction(id: IceWindowIdentifier) {
        callAsFunction(id: id.rawValue)
    }
}

// MARK: - DismissWindowAction

extension DismissWindowAction {
    /// Dismisses the corresponding window for the given identifier.
    ///
    /// - Parameter id: An identifier for one of Ice's windows.
    func callAsFunction(id: IceWindowIdentifier) {
        callAsFunction(id: id.rawValue)
    }
}
