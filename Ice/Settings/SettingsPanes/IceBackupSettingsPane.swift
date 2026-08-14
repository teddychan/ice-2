//
//  IceBackupSettingsPane.swift
//  Ice
//

import DragonKit
import SwiftUI

/// Ice 2's own folder-based backup pane — **temporary, and on its way out.**
///
/// DragonKit's `BackupSettingsPane` + `DragonBackup` is the target for every Dragon app. This
/// pane and ClipMenu 2's `SyncBackupPane` are the two that have not migrated yet, because their
/// data and workflows have to be mapped across safely first. That is approved migration debt,
/// tracked in dragon-kit's `TechDebt.md` — a sequenced difference, not a permanent one, and the
/// same handling applies to all five apps.
///
/// **Not a CONFORMANCE §R11 exception**, which this comment used to cite: ice-2 declares no
/// `exceptions` at all, and none is needed. §R3 and §R4 never fire on this pane — the `Ice`
/// prefix keeps the name from shadowing the kit's, and it hand-rolls no grouped `Form` — so an
/// exception here would sanction a violation that does not exist, which §R11's own table records
/// as the mistake to avoid. What actually carries this pane is **§R9**, whose Backup slot
/// recognizes the app-specific spelling and still holds it to the canonical sidebar position.
///
/// Ice 2 keeps versioned backup files in a user-chosen folder so settings can sync across Macs;
/// `DragonBackup` snapshots a single UserDefaults suite. The migration adds that capability once,
/// in the kit — it is not preserved here.
struct IceBackupSettingsPane: View {
    @EnvironmentObject var appState: AppState

    /// Backup folder. Defaults to ~/Documents/Ice Backups; the user can point it
    /// at a Dropbox / iCloud Drive / Google Drive folder to sync across Macs.
    @AppStorage(Defaults.Key.backupFolderPath.rawValue) private var backupFolderPath = ""
    @AppStorage(Defaults.Key.automaticBackupEnabled.rawValue) private var automaticBackup = true

    @State private var backups: [BackupItem] = []
    @State private var status: String?
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
        DragonForm {
            DragonSection {
                Text(L("DragonKit.backup.folderSection"))
            } content: {
                folderRow
                automaticBackupToggle
            }
            DragonSection {
                Text(L("DragonKit.backup.backupsSection"))
            } content: {
                backupActions
                backupList
            }
        }
        .onAppear(perform: refresh)
        .alert(
            L("app.backup.restoreConfirmTitle"),
            isPresented: Binding(
                get: { restoreCandidate != nil },
                set: { if !$0 { restoreCandidate = nil } }
            ),
            presenting: restoreCandidate
        ) { item in
            Button(L("app.backup.restoreAndRelaunch"), role: .destructive) {
                restore(item)
            }
            Button(L("DragonKit.cancel"), role: .cancel) {}
        } message: { item in
            Text(String(
                format: L("app.backup.restoreConfirmMessage"),
                Self.dateFormatter.string(from: item.date)
            ))
        }
        .alert(
            L("DragonKit.backup.errorTitle"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(L("DragonKit.ok"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: Folder

    @ViewBuilder
    private var folderRow: some View {
        LabeledContent {
            Button(L("DragonKit.backup.choose"), action: chooseFolder)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(L("app.backup.location"))
                Text(folderURL.path(percentEncoded: false))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .dragonAnnotation { Text(L("app.backup.location.note")) }
    }

    @ViewBuilder
    private var automaticBackupToggle: some View {
        Toggle(L("app.backup.automatic"), isOn: $automaticBackup)
            .dragonAnnotation { Text(L("app.backup.automatic.note")) }
    }

    // MARK: Backups

    @ViewBuilder
    private var backupActions: some View {
        LabeledContent {
            HStack {
                Button(L("DragonKit.backup.reveal"), action: revealFolder)
                Button(L("DragonKit.backup.now"), action: backUpNow)
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(L("app.backup.manual"))
                if let status {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .dragonAnnotation {
            Text(String(
                format: L("app.backup.retention.note"),
                SettingsBackup.defaultRetentionLimit
            ))
        }
    }

    @ViewBuilder
    private var backupList: some View {
        if backups.isEmpty {
            Text(L("DragonKit.backup.none"))
                .foregroundStyle(.secondary)
        } else {
            ForEach(backups) { item in
                LabeledContent {
                    HStack {
                        Button(L("DragonKit.backup.restore")) { restoreCandidate = item }
                        Button(L("app.common.delete"), role: .destructive) { delete(item) }
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
        // Enforce the retention limit on view, so a folder that already holds more
        // than the limit (e.g. synced from another Mac) is reconciled down to it.
        SettingsBackup.prune(in: folderURL, keeping: SettingsBackup.defaultRetentionLimit)
        backups = SettingsBackup.listBackups(in: folderURL).map { url in
            let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate ?? .distantPast
            return BackupItem(url: url, date: date)
        }
    }

    private func backUpNow() {
        do {
            _ = try SettingsBackup.performBackup(date: Date())
            status = L("app.backup.status.justNow")
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
        panel.prompt = L("app.backup.choosePanelPrompt")
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
