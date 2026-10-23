import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import ZIPFoundation

struct Day5BackupExportView: View {
    @Query(sort: \NoteEntity.createdAtUTC) private var notes: [NoteEntity]
    @Query(sort: \FollowupEntity.createdAtUTC) private var followups: [FollowupEntity]
    @EnvironmentObject private var session: AppSessionViewModel

    @State private var document: NotesBackupDocument?
    @State private var isExporting = false
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section {
                LabeledContent("Notes", value: "\(notes.count)")
                LabeledContent("Follow-ups", value: "\(followups.count)")
                Button("Export ZIP Backup") {
                    prepareBackup()
                }
                .disabled(session.isSyncing || (notes.isEmpty && followups.isEmpty))
            } header: {
                Text("Notes Backup")
            } footer: {
                Text("Exports the notes and follow-ups currently loaded in the app, including summaries. Refresh your notes first to include the latest changes.")
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                }
            }
        }
        .navigationTitle("Export Backup")
        .fileExporter(
            isPresented: $isExporting,
            document: document,
            contentTypes: [.zip],
            defaultFilename: "DentalNotes-Backup"
        ) { result in
            switch result {
            case .success(let url):
                statusMessage = "Saved \(url.lastPathComponent)."
            case .failure(let error):
                statusMessage = "Export failed: \(error.localizedDescription)"
            }
            document = nil
        } onCancellation: {
            statusMessage = "Export cancelled. No backup was saved."
            document = nil
        }
    }

    private func prepareBackup() {
        statusMessage = nil
        do {
            let backup = NotesBackup(
                exportedAtUTC: Date(),
                notes: notes.map { note in
                    NotesBackup.Note(
                        id: note.id,
                        value: note.value,
                        summary: note.summary,
                        balanceDueAmount: note.balanceDueAmount,
                        balanceDueCurrency: note.balanceDueCurrency,
                        categories: note.categories,
                        appointmentTiming: note.appointmentTiming,
                        createdAtUTC: note.createdAtUTC,
                        editedAtUTC: note.editedAtUTC
                    )
                },
                followups: followups.map { followup in
                    NotesBackup.Followup(
                        id: followup.id,
                        descriptionText: followup.descriptionText,
                        type: followup.type,
                        noteID: followup.noteID,
                        createdAtUTC: followup.createdAtUTC,
                        editedAtUTC: followup.editedAtUTC,
                        isCompleted: followup.isCompleted
                    )
                }
            )
            document = NotesBackupDocument(data: try backup.zipData())
            isExporting = true
        } catch {
            statusMessage = "Export failed: \(error.localizedDescription)"
        }
    }
}

private struct NotesBackupDocument: FileDocument {
    nonisolated static var readableContentTypes: [UTType] { [.zip] }
    let data: Data

    init(data: Data) {
        self.data = data
    }

    nonisolated init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    nonisolated func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
