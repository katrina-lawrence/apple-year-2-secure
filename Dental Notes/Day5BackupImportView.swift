import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import ZIPFoundation

struct Day5BackupImportView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var session: AppSessionViewModel
    @State private var isSelectingBackup = false
    @State private var isImporting = false
    @State private var statusMessage = "Restore missing notes and follow-ups from a ZIP backup to your signed-in account. Existing records stay unchanged."

    private var zipContentType: UTType {
        UTType(filenameExtension: "zip") ?? .data
    }

    var body: some View {
        Form {
            Section("Notes Backup") {
                Text(statusMessage)
                    .foregroundStyle(.secondary)

                Button("Choose ZIP Backup") {
                    isSelectingBackup = true
                }
                .disabled(isImporting || session.isSyncing || !session.isAuthenticated)

                if isImporting {
                    ProgressView("Restoring backup…")
                }
            }
        }
        .navigationTitle("Import Backup")
        .interactiveDismissDisabled(isImporting)
        .navigationBarBackButtonHidden(isImporting)
        .fileImporter(
            isPresented: $isSelectingBackup,
            allowedContentTypes: [zipContentType]
        ) { result in
            switch result {
            case .success(let archiveURL):
                Task { await importBackup(from: archiveURL) }
            case .failure(let error):
                statusMessage = "Import failed: \(error.localizedDescription)"
            }
        }
    }

    private func importBackup(from archiveURL: URL) async {
        isImporting = true
        statusMessage = "Restoring backup…"
        defer { isImporting = false }
        let hasSecurityScope = archiveURL.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScope {
                archiveURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let fileManager = FileManager.default
            guard let applicationSupportURL = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first else {
                throw CocoaError(.fileNoSuchFile)
            }

            let destinationURL = applicationSupportURL
                .appendingPathComponent("ImportedNotes", isDirectory: true)
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            try fileManager.createDirectory(
                at: destinationURL,
                withIntermediateDirectories: true
            )
            defer { try? fileManager.removeItem(at: destinationURL) }

            try fileManager.unzipItem(at: archiveURL, to: destinationURL)
            let jsonURL = destinationURL.appendingPathComponent("notes.json")
            guard fileManager.fileExists(atPath: jsonURL.path) else {
                throw BackupImportError.invalidBackup
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup: NotesBackup
            do {
                backup = try decoder.decode(NotesBackup.self, from: Data(contentsOf: jsonURL))
            } catch {
                throw BackupImportError.invalidBackup
            }
            guard backup.formatVersion == 1 else {
                throw BackupImportError.unsupportedVersion
            }
            let result = try await session.restoreBackup(backup)
            let refreshed = await session.refreshUserData(modelContext: modelContext)
            statusMessage = "Restored \(result.restoredNotes) notes and \(result.restoredFollowups) follow-ups. Kept \(result.skippedNotes) existing notes and \(result.skippedFollowups) existing follow-ups."
            if !refreshed {
                statusMessage += " Saved to your account, but the list could not refresh. Refresh Notes when the server is available."
            }
        } catch {
            statusMessage = "Import failed: \(error.localizedDescription)"
        }
    }
}

struct BackupRestoreResult: Decodable {
    let restoredNotes: Int
    let restoredFollowups: Int
    let skippedNotes: Int
    let skippedFollowups: Int
}

private enum BackupImportError: LocalizedError {
    case invalidBackup
    case unsupportedVersion

    var errorDescription: String? {
        switch self {
        case .invalidBackup:
            return "This ZIP does not contain a valid notes.json backup."
        case .unsupportedVersion:
            return "This backup version is not supported."
        }
    }
}
