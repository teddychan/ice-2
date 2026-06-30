//
//  UninstallView.swift
//  Ice
//

import AppKit
import SwiftUI

// Standardized Uninstall confirmation (liquid-glass §5A): a destructive sheet that
// names exactly what it removes, with Uninstall (red, destructive, LEFT) and Cancel
// (the default, RIGHT) so Return/Esc both land on the safe choice. Ice keeps no
// separate user data (its settings ARE its data, always removed), so there is no
// "also delete data" toggle here — unlike ClipMenu.

/// Hosts `UninstallView` in a small window (Ice is an LSUIElement agent).
@MainActor
final class UninstallWindowController {
    static let shared = UninstallWindowController()
    private var window: NSWindow?

    func present(onConfirm: @escaping () -> Void) {
        if let window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }
        let view = UninstallView(
            onCancel: { [weak self] in self?.window?.close() },
            onUninstall: { [weak self] in
                self?.window?.close()
                onConfirm()
            }
        )
        let win = NSWindow(contentViewController: NSHostingController(rootView: view))
        win.styleMask = [.titled, .closable]
        win.title = ""
        win.isReleasedWhenClosed = false
        win.center()
        window = win

        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
    }
}

struct UninstallView: View {
    let onCancel: () -> Void
    let onUninstall: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "trash")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 9))
                Text("Uninstall Ice 2?")
                    .font(.title2).bold()
            }

            Text("Ice 2 will quit and remove itself completely. This will delete:")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                checkRow("The app and its login item")
                checkRow("Settings, layout profiles, and hotkeys")
                checkRow("Saved application state")
            }

            Text("Accessibility and Screen Recording permissions must be removed by you in System Settings ▸ Privacy & Security — macOS does not let the app revoke them. This cannot be undone.")
                .font(.caption).foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button(role: .destructive) { onUninstall() } label: {
                    Text("Uninstall").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.defaultAction)   // Return/Esc → the safe choice
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
        }
        .padding(20)
        .frame(width: 420)
    }

    private func checkRow(_ text: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        }
    }
}
