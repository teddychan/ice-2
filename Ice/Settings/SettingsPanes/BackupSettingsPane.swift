//
//  BackupSettingsPane.swift
//  Ice
//

import SwiftUI

struct BackupSettingsPane: View {
    @EnvironmentObject var appState: AppState

    /// Backup folder. Defaults to ~/Documents/Ice Backups; the user can point it
    /// at a Dropbox / iCloud Drive / Google Drive folder to sync across Macs.
    @AppStorage(Defaults.Key.backupFolderPath.rawValue) private var backupFolderPath = ""
    @AppStorage(Defaults.Key.automaticBackupEnabled.rawValue) private var automaticBackup = true

    @State private var backups: [BackupItem] = []
    @State private var status: LocalizedStringKey?
    @State private var errorMessage: String?
    @State private var restoreCandidate: BackupItem?

    private struct BackupItem: Identifiable {
        let url: URL
        let date: Date
        var id: URL { url }
    }

    private var folderURL: URL {
        if !backupFolderPath.isEmpty {
            return URL(fileURLWithPath: backupFolderPath, isDirectory: true)
        }
        return SettingsBackup.defaultFolder()
    }

    var body: some View {
        IceForm {
            IceSection("Backup Folder") {
                folderRow
                automaticBackupToggle
            }
            IceSection("Backups") {
                backupActions
                backupList
            }
        }
        .onAppear(perform: refresh)
        .alert(
            "Restore settings?",
            isPresented: Binding(
                get: { restoreCandidate != nil },
                set: { if !$0 { restoreCandidate = nil } }
            ),
            presenting: restoreCandidate
        ) { item in
            Button("Restore and Relaunch", role: .destructive) {
                restore(item)
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("This replaces all current Ice 2 settings with the backup from \(Self.dateFormatter.string(from: item.date)), then relaunches Ice 2.")
        }
        .alert(
            "Backup Error",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: Folder

    @ViewBuilder
    private var folderRow: some View {
        LabeledContent {
            Button("Change…", action: chooseFolder)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("Location")
                Text(folderURL.path(percentEncoded: false))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .annotation("Choose a folder inside Dropbox, iCloud Drive, or Google Drive to sync your settings across your Macs. Backups are also kept for restoring after a reinstall or on a new Mac.")
    }

    @ViewBuilder
    private var automaticBackupToggle: some View {
        Toggle("Automatically back up when quitting", isOn: $automaticBackup)
            .annotation("Keeps the backup folder current so a synced copy is always up to date.")
    }

    // MARK: Backups

    @ViewBuilder
    private var backupActions: some View {
        LabeledContent {
            HStack {
                Button("Reveal in Finder", action: revealFolder)
                Button("Back Up Now", action: backUpNow)
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("Manual backup")
                if let status {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .annotation("The newest \(SettingsBackup.defaultRetentionLimit) backups are kept; older ones are removed automatically.")
    }

    @ViewBuilder
    private var backupList: some View {
        if backups.isEmpty {
            Text("No backups yet.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(backups) { item in
                LabeledContent {
                    HStack {
                        Button("Restore") { restoreCandidate = item }
                        Button("Delete", role: .destructive) { delete(item) }
                    }
                } label: {
                    Text(Self.dateFormatter.string(from: item.date))
                }
                .frame(height: 22)
            }
        }
    }

    // MARK: Actions

    private func refresh() {
        backups = SettingsBackup.listBackups(in: folderURL).map { url in
            let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate ?? .distantPast
            return BackupItem(url: url, date: date)
        }
    }

    private func backUpNow() {
        do {
            _ = try SettingsBackup.performBackup(date: Date())
            status = "Backed up just now."
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func restore(_ item: BackupItem) {
        do {
            try SettingsBackup.restore(from: item.url, into: .standard)
            appState.relaunch()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ item: BackupItem) {
        try? FileManager.default.removeItem(at: item.url)
        refresh()
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.directoryURL = folderURL
        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }
        backupFolderPath = url.path(percentEncoded: false)
        refresh()
    }

    private func revealFolder() {
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([folderURL])
    }

    // MARK: Helpers

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
