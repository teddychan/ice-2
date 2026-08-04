//
//  UpdatesSettingsPane.swift
//  Ice
//

import DragonKit
import SwiftUI

/// Update preferences, split out of the About pane to match the shared
/// app settings taxonomy (General · Appearance · Hotkeys · Updates · About).
struct UpdatesSettingsPane: View {
    @ObservedObject var updatesManager: UpdatesManager

    private var lastUpdateCheckString: String {
        if let date = updatesManager.lastUpdateCheckDate {
            date.formatted(date: .abbreviated, time: .standard)
        } else {
            "Never"
        }
    }

    var body: some View {
        DragonForm {
            DragonSection {
                Toggle(
                    "Automatically check for updates",
                    isOn: $updatesManager.automaticallyChecksForUpdates
                )
                Toggle(
                    "Automatically download updates",
                    isOn: $updatesManager.automaticallyDownloadsUpdates
                )
            }
            DragonSection {
                LabeledContent {
                    Button("Check for Updates…") {
                        updatesManager.checkForUpdates()
                    }
                    .disabled(!updatesManager.canCheckForUpdates)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Check for updates now")
                        Text("Last checked: \(lastUpdateCheckString)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
