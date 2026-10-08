import SwiftData
import SwiftUI

private enum TextLimits {
    static let maxLength = 512
    static let previewLength = 80
}

@Model
final class NoteEntity {
    @Attribute(.unique) var id: UUID
    var value: String
    var createdAtUTC: Date
    var editedAtUTC: Date

    init(
        id: UUID = UUID(),
        value: String,
        createdAtUTC: Date = Date(),
        editedAtUTC: Date = Date()
    ) {
        self.id = id
        self.value = value
        self.createdAtUTC = createdAtUTC
        self.editedAtUTC = editedAtUTC
    }
}

@Model
final class FollowupEntity {
    @Attribute(.unique) var id: UUID
    var descriptionText: String
    var noteID: UUID
    var appointmentAtUTC: Date
    var createdAtUTC: Date
    var editedAtUTC: Date
    var completedAtUTC: Date?

    init(
        id: UUID = UUID(),
        descriptionText: String,
        noteID: UUID,
        appointmentAtUTC: Date,
        createdAtUTC: Date = Date(),
        editedAtUTC: Date = Date(),
        completedAtUTC: Date? = nil
    ) {
        self.id = id
        self.descriptionText = descriptionText
        self.noteID = noteID
        self.appointmentAtUTC = appointmentAtUTC
        self.createdAtUTC = createdAtUTC
        self.editedAtUTC = editedAtUTC
        self.completedAtUTC = completedAtUTC
    }
}

private enum AppDateFormatter {
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static func display(_ date: Date) -> String {
        dateTime.string(from: date)
    }
}

private extension String {
    var firstLineTrimmed: String {
        components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func preview(maxLength: Int = TextLimits.previewLength) -> String {
        let line = firstLineTrimmed
        guard !line.isEmpty else { return "(Empty)" }
        guard line.count > maxLength else { return line }
        return String(line.prefix(maxLength - 1)) + "…"
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            NotesTabView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }

            FollowupsTabView()
                .tabItem {
                    Label("Followups", systemImage: "calendar")
                }
        }
    }
}

private struct NotesTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NoteEntity.createdAtUTC, order: .reverse) private var notes: [NoteEntity]
    @Query private var allFollowups: [FollowupEntity]

    @State private var showingCreateNote = false
    @State private var notePendingDelete: NoteEntity?

    var body: some View {
        NavigationStack {
            List {
                if notes.isEmpty {
                    ContentUnavailableView(
                        "No Notes",
                        systemImage: "note.text",
                        description: Text("Tap + to add your first dental note.")
                    )
                } else {
                    ForEach(notes) { note in
                        NavigationLink {
                            NoteDetailView(note: note)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.value.preview())
                                Text(AppDateFormatter.display(note.createdAtUTC))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                notePendingDelete = note
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateNote = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateNote) {
                NoteEditorSheet()
            }
            .alert("Delete Note?", isPresented: Binding(get: {
                notePendingDelete != nil
            }, set: { newValue in
                if !newValue {
                    notePendingDelete = nil
                }
            })) {
                Button("Delete", role: .destructive) {
                    guard let note = notePendingDelete else { return }
                    deleteNoteWithFollowups(note)
                    notePendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    notePendingDelete = nil
                }
            } message: {
                Text("This also deletes all followups associated with this note.")
            }
        }
    }

    private func deleteNoteWithFollowups(_ note: NoteEntity) {
        let related = allFollowups.filter { $0.noteID == note.id }
        for followup in related {
            modelContext.delete(followup)
        }
        modelContext.delete(note)
        try? modelContext.save()
    }
}

private struct FollowupsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FollowupEntity.appointmentAtUTC, order: .reverse) private var followups: [FollowupEntity]

    @State private var followupPendingDelete: FollowupEntity?

    var body: some View {
        NavigationStack {
            List {
                if followups.isEmpty {
                    ContentUnavailableView(
                        "No Followups",
                        systemImage: "calendar",
                        description: Text("Add a followup from a note.")
                    )
                } else {
                    ForEach(followups) { followup in
                        NavigationLink {
                            FollowupDetailView(followup: followup)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(AppDateFormatter.display(followup.appointmentAtUTC))
                                    .fontWeight(.semibold)
                                Text(followup.descriptionText.preview())
                                    .foregroundStyle(followup.completedAtUTC == nil ? .primary : .secondary)
                                    .strikethrough(followup.completedAtUTC != nil)
                            }
                            .opacity(followup.completedAtUTC == nil ? 1 : 0.65)
                            .padding(.vertical, 2)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                followupPendingDelete = followup
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Followups")
            .alert("Delete Followup?", isPresented: Binding(get: {
                followupPendingDelete != nil
            }, set: { newValue in
                if !newValue {
                    followupPendingDelete = nil
                }
            })) {
                Button("Delete", role: .destructive) {
                    guard let followup = followupPendingDelete else { return }
                    modelContext.delete(followup)
                    try? modelContext.save()
                    followupPendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    followupPendingDelete = nil
                }
            }
        }
    }
}

private struct NoteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let note: NoteEntity

    @Query(sort: \FollowupEntity.appointmentAtUTC, order: .reverse) private var allFollowups: [FollowupEntity]

    @State private var showingEditNote = false
    @State private var showingCreateFollowup = false
    @State private var notePendingDelete = false

    private var associatedFollowups: [FollowupEntity] {
        allFollowups.filter { $0.noteID == note.id }
    }

    var body: some View {
        List {
            Section("Note") {
                LabeledContent("Created") {
                    Text(AppDateFormatter.display(note.createdAtUTC))
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Edited") {
                    Text(AppDateFormatter.display(note.editedAtUTC))
                        .multilineTextAlignment(.trailing)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(note.value.isEmpty ? "(Empty)" : note.value)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
            }

            Section("Followups") {
                if associatedFollowups.isEmpty {
                    Text("No followups for this note.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(associatedFollowups) { followup in
                        NavigationLink {
                            FollowupDetailView(followup: followup)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(AppDateFormatter.display(followup.appointmentAtUTC))
                                    .fontWeight(.semibold)
                                Text(followup.descriptionText.preview())
                                    .foregroundStyle(followup.completedAtUTC == nil ? .primary : .secondary)
                                    .strikethrough(followup.completedAtUTC != nil)
                            }
                            .opacity(followup.completedAtUTC == nil ? 1 : 0.65)
                        }
                    }
                }

                Button {
                    showingCreateFollowup = true
                } label: {
                    Label("Add Followup", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Note")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditNote = true
                }
                Button(role: .destructive) {
                    notePendingDelete = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEditNote) {
            NoteEditorSheet(note: note)
        }
        .sheet(isPresented: $showingCreateFollowup) {
            FollowupEditorSheet(noteID: note.id)
        }
        .alert("Delete Note?", isPresented: $notePendingDelete) {
            Button("Delete", role: .destructive) {
                for followup in associatedFollowups {
                    modelContext.delete(followup)
                }
                modelContext.delete(note)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This also deletes all followups associated with this note.")
        }
    }
}

private struct FollowupDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let followup: FollowupEntity

    @Query private var notes: [NoteEntity]

    @State private var showingEditFollowup = false
    @State private var followupPendingDelete = false

    private var associatedNote: NoteEntity? {
        notes.first { $0.id == followup.noteID }
    }

    var body: some View {
        List {
            Section("Appointment") {
                LabeledContent("Date") {
                    Text(AppDateFormatter.display(followup.appointmentAtUTC))
                }
                LabeledContent("Created") {
                    Text(AppDateFormatter.display(followup.createdAtUTC))
                }
                LabeledContent("Edited") {
                    Text(AppDateFormatter.display(followup.editedAtUTC))
                }
                LabeledContent("Completed") {
                    Text(followup.completedAtUTC.map(AppDateFormatter.display) ?? "Not completed")
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(followup.descriptionText.isEmpty ? "(Empty)" : followup.descriptionText)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)

                Button {
                    setCompleted(to: followup.completedAtUTC == nil)
                } label: {
                    Label(
                        followup.completedAtUTC == nil ? "Mark Completed" : "Mark Incomplete",
                        systemImage: followup.completedAtUTC == nil ? "checkmark.circle" : "xmark.circle"
                    )
                }
            }

            Section("Associated Note") {
                if let note = associatedNote {
                    NavigationLink {
                        NoteDetailView(note: note)
                    } label: {
                        Text(note.value.preview())
                    }
                } else {
                    Text("Note not found")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Followup")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditFollowup = true
                }
                Button(role: .destructive) {
                    followupPendingDelete = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEditFollowup) {
            FollowupEditorSheet(existingFollowup: followup)
        }
        .alert("Delete Followup?", isPresented: $followupPendingDelete) {
            Button("Delete", role: .destructive) {
                modelContext.delete(followup)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func setCompleted(to completed: Bool) {
        followup.completedAtUTC = completed ? Date() : nil
        followup.editedAtUTC = Date()
        try? modelContext.save()
    }
}

private struct NoteEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let note: NoteEntity?

    @State private var value: String

    init(note: NoteEntity? = nil) {
        self.note = note
        _value = State(initialValue: note?.value ?? "")
    }

    private var isTooLong: Bool {
        value.count > TextLimits.maxLength
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $value)
                        .frame(minHeight: 220)
                    HStack {
                        Spacer()
                        Text("\(value.count)/\(TextLimits.maxLength)")
                            .font(.caption)
                            .foregroundStyle(isTooLong ? .red : .secondary)
                    }
                    if isTooLong {
                        Text("Note must be 512 characters or fewer.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(isTooLong)
                }
            }
        }
    }

    private func save() {
        let now = Date()
        if let note {
            note.value = value
            note.editedAtUTC = now
        } else {
            let created = NoteEntity(value: value, createdAtUTC: now, editedAtUTC: now)
            modelContext.insert(created)
        }

        try? modelContext.save()
        dismiss()
    }
}

private struct FollowupEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let noteID: UUID
    let existingFollowup: FollowupEntity?

    @State private var descriptionText: String
    @State private var appointmentAtUTC: Date

    init(noteID: UUID? = nil, existingFollowup: FollowupEntity? = nil) {
        let resolvedNoteID = noteID ?? existingFollowup?.noteID ?? UUID()
        self.noteID = resolvedNoteID
        self.existingFollowup = existingFollowup
        _descriptionText = State(initialValue: existingFollowup?.descriptionText ?? "")
        _appointmentAtUTC = State(initialValue: existingFollowup?.appointmentAtUTC ?? Date())
    }

    private var isTooLong: Bool {
        descriptionText.count > TextLimits.maxLength
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Appointment") {
                    DatePicker(
                        "Appointment Time",
                        selection: $appointmentAtUTC,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section("Description") {
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 180)
                    HStack {
                        Spacer()
                        Text("\(descriptionText.count)/\(TextLimits.maxLength)")
                            .font(.caption)
                            .foregroundStyle(isTooLong ? .red : .secondary)
                    }
                    if isTooLong {
                        Text("Description must be 512 characters or fewer.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(existingFollowup == nil ? "New Followup" : "Edit Followup")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(isTooLong)
                }
            }
        }
    }

    private func save() {
        let now = Date()
        if let existingFollowup {
            existingFollowup.descriptionText = descriptionText
            existingFollowup.appointmentAtUTC = appointmentAtUTC
            existingFollowup.editedAtUTC = now
        } else {
            let followup = FollowupEntity(
                descriptionText: descriptionText,
                noteID: noteID,
                appointmentAtUTC: appointmentAtUTC,
                createdAtUTC: now,
                editedAtUTC: now
            )
            modelContext.insert(followup)
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [NoteEntity.self, FollowupEntity.self], inMemory: true)
}
