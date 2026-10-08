import SwiftData
import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

private enum TextLimits {
    static let maxLength = 2048
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

private struct ProposedFollowup: Identifiable, Hashable {
    let id: UUID
    let descriptionText: String
    let appointmentAtUTC: Date

    init(id: UUID = UUID(), descriptionText: String, appointmentAtUTC: Date) {
        self.id = id
        self.descriptionText = descriptionText
        self.appointmentAtUTC = appointmentAtUTC
    }
}

#if canImport(FoundationModels)
@Generable
private struct AIFollowupDraft {
    var descriptionText: String
    var confidence: Double
    var scheduleType: String
    var offsetValue: Int?
    var offsetUnit: String?
    var absoluteAtISO8601UTC: String?
}

@Generable
private struct AIFollowupDraftList {
    var followups: [AIFollowupDraft]
}

private enum NoteFollowupAIService {
    static func isAvailable() -> Bool {
        switch SystemLanguageModel.default.availability {
        case .available:
            return true
        case .unavailable:
            return false
        @unknown default:
            return false
        }
    }

    static func generateProposals(from noteText: String, referenceDate: Date) async throws -> [ProposedFollowup] {
        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNote.isEmpty else { return [] }

        let referenceISO = ISO8601DateFormatter().string(from: referenceDate)
        let session = LanguageModelSession(instructions: """
        You generate practical dental followups from a note.
        Return JSON-compatible structured output only through the provided schema.
        Keep suggestions concise and clinically relevant.
        """)
        let prompt = """
        Analyze the following dental note and propose followups only when confidence is high.
        It is valid to return zero followups.

        For each followup include:
        - descriptionText: a clear short action.
        - confidence: decimal in [0, 1].
        - scheduleType: "relative" or "absolute".
        - If scheduleType is "relative":
          - offsetValue: positive integer.
          - offsetUnit: "days", "months", or "years".
          - absoluteAtISO8601UTC should be null.
        - If scheduleType is "absolute":
          - absoluteAtISO8601UTC: valid ISO-8601 datetime string in UTC (example: 2026-10-10T09:30:00Z).
          - offsetValue and offsetUnit should be null.

        Use "relative" for timelines like "in 7 days", "in 6 months", "in 1 year".
        Use "absolute" only when a specific date is clearly present or strongly implied.
        Do not include low-confidence followups.

        Reference date (note created date): \(referenceISO)

        Note:
        \(trimmedNote)
        """

        let response = try await session.respond(to: prompt, generating: AIFollowupDraftList.self)
        return response.content.followups.prefix(8).compactMap { draft in
            let description = draft.descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !description.isEmpty else { return nil }
            guard draft.confidence >= 0.8 else { return nil }

            guard let date = resolvedDate(from: draft, referenceDate: referenceDate) else { return nil }
            return ProposedFollowup(descriptionText: description, appointmentAtUTC: date)
        }
    }

    private static func resolvedDate(from draft: AIFollowupDraft, referenceDate: Date) -> Date? {
        let type = draft.scheduleType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if type == "relative",
           let offsetValue = draft.offsetValue,
           offsetValue > 0,
           let offsetUnit = draft.offsetUnit?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            var component: Calendar.Component?
            switch offsetUnit {
            case "day", "days":
                component = .day
            case "month", "months":
                component = .month
            case "year", "years":
                component = .year
            default:
                component = nil
            }

            if let component {
                return Calendar.current.date(byAdding: component, value: offsetValue, to: referenceDate)
            }
        }

        if let rawAbsolute = draft.absoluteAtISO8601UTC {
            return parsedDate(from: rawAbsolute)
        }

        return nil
    }

    private static func parsedDate(from text: String) -> Date? {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }

        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterWithFractional.date(from: raw) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: raw)
    }
}
#else
private enum NoteFollowupAIService {
    static func isAvailable() -> Bool { false }
    static func generateProposals(from noteText: String, referenceDate: Date) async throws -> [ProposedFollowup] { [] }
}
#endif

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

    @State private var hideCompleted = false
    @State private var followupPendingDelete: FollowupEntity?

    private var displayedFollowups: [FollowupEntity] {
        hideCompleted ? followups.filter { $0.completedAtUTC == nil } : followups
    }

    var body: some View {
        NavigationStack {
            List {
                Toggle("Hide Completed", isOn: $hideCompleted)

                if displayedFollowups.isEmpty {
                    ContentUnavailableView(
                        "No Followups",
                        systemImage: "calendar",
                        description: Text(hideCompleted ? "No incomplete followups." : "Add a followup from a note.")
                    )
                } else {
                    ForEach(displayedFollowups) { followup in
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
    @State private var aiAvailable = false
    @State private var isProcessingWithAI = false
    @State private var aiProcessError: String?
    @State private var aiHasProcessed = false
    @State private var proposedFollowups: [ProposedFollowup] = []
    @State private var pendingDuplicateConfirmation: ProposedFollowup?

    private var associatedFollowups: [FollowupEntity] {
        allFollowups.filter { $0.noteID == note.id }
    }

    private var duplicateAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDuplicateConfirmation != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDuplicateConfirmation = nil
                }
            }
        )
    }

    var body: some View {
        List {
            NoteMetadataSection(note: note)
            followupsSection
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
        .alert(
            "Create Similar Followup?",
            isPresented: duplicateAlertBinding,
            presenting: pendingDuplicateConfirmation
        ) { proposal in
            Button("Create", role: .destructive) {
                insertFollowupFromProposal(proposal)
                pendingDuplicateConfirmation = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDuplicateConfirmation = nil
            }
        } message: {_ in 
            Text("A similar followup already exists for this note. Create this one anyway?")
        }
        .onAppear {
            aiAvailable = NoteFollowupAIService.isAvailable()
        }
    }

    private var followupsSection: some View {
        Section("Followups") {
            ExistingFollowupsList(followups: associatedFollowups)

            Button {
                showingCreateFollowup = true
            } label: {
                Label("Add Followup", systemImage: "plus")
            }

            AIProcessingControls(
                aiAvailable: aiAvailable,
                isProcessingWithAI: isProcessingWithAI,
                aiProcessError: aiProcessError,
                aiHasProcessed: aiHasProcessed,
                proposedFollowups: proposedFollowups,
                onProcess: processWithAI,
                onCreateProposal: createFollowupFromProposal
            )
        }
    }

    private func processWithAI() {
        guard !isProcessingWithAI else { return }

        isProcessingWithAI = true
        aiProcessError = nil

        Task {
            do {
                let generated = try await NoteFollowupAIService.generateProposals(
                    from: note.value,
                    referenceDate: note.createdAtUTC
                )
                await MainActor.run {
                    proposedFollowups = generated
                    aiHasProcessed = true
                    isProcessingWithAI = false
                }
            } catch {
                await MainActor.run {
                    aiProcessError = "Could not generate followups right now."
                    proposedFollowups = []
                    aiHasProcessed = true
                    isProcessingWithAI = false
                }
            }
        }
    }

    private func createFollowupFromProposal(_ proposal: ProposedFollowup) {
        if hasSimilarFollowup(for: proposal) {
            pendingDuplicateConfirmation = proposal
            return
        }
        insertFollowupFromProposal(proposal)
    }

    private func insertFollowupFromProposal(_ proposal: ProposedFollowup) {
        let now = Date()
        let followup = FollowupEntity(
            descriptionText: proposal.descriptionText,
            noteID: note.id,
            appointmentAtUTC: proposal.appointmentAtUTC,
            createdAtUTC: now,
            editedAtUTC: now
        )
        modelContext.insert(followup)
        try? modelContext.save()
        proposedFollowups.removeAll { $0.id == proposal.id }
    }

    private func hasSimilarFollowup(for proposal: ProposedFollowup) -> Bool {
        let target = normalizedText(proposal.descriptionText)
        guard !target.isEmpty else { return false }

        return associatedFollowups.contains { followup in
            let candidate = normalizedText(followup.descriptionText)
            guard !candidate.isEmpty else { return false }

            if target == candidate || target.contains(candidate) || candidate.contains(target) {
                return true
            }

            let targetTokens = Set(target.split(separator: " ").map(String.init))
            let candidateTokens = Set(candidate.split(separator: " ").map(String.init))
            guard !targetTokens.isEmpty, !candidateTokens.isEmpty else { return false }

            let overlap = targetTokens.intersection(candidateTokens).count
            let denominator = min(targetTokens.count, candidateTokens.count)
            guard denominator > 0 else { return false }

            let overlapRatio = Double(overlap) / Double(denominator)
            return overlapRatio >= 0.7
        }
    }

    private func normalizedText(_ text: String) -> String {
        let lowered = text.lowercased()
        let scalars = lowered.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : " "
        }
        return String(scalars).replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct NoteMetadataSection: View {
    let note: NoteEntity

    var body: some View {
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
    }
}

private struct ExistingFollowupsList: View {
    let followups: [FollowupEntity]

    var body: some View {
        if followups.isEmpty {
            Text("No followups for this note.")
                .foregroundStyle(.secondary)
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
                }
            }
        }
    }
}

private struct AIProcessingControls: View {
    let aiAvailable: Bool
    let isProcessingWithAI: Bool
    let aiProcessError: String?
    let aiHasProcessed: Bool
    let proposedFollowups: [ProposedFollowup]
    let onProcess: () -> Void
    let onCreateProposal: (ProposedFollowup) -> Void

    var body: some View {
        if aiAvailable {
            Button {
                onProcess()
            } label: {
                Label("Process", systemImage: "wand.and.stars")
            }
            .disabled(isProcessingWithAI)

            if isProcessingWithAI {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Generating proposals…")
                        .foregroundStyle(.secondary)
                }
            }

            if let aiProcessError {
                Text(aiProcessError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if aiHasProcessed && proposedFollowups.isEmpty && aiProcessError == nil {
                Text("No followup proposals were generated.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(proposedFollowups) { proposal in
                AIFollowupProposalRow(proposal: proposal, onCreate: onCreateProposal)
            }
        }
    }
}

private struct AIFollowupProposalRow: View {
    let proposal: ProposedFollowup
    let onCreate: (ProposedFollowup) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(proposal.descriptionText)
            Text(AppDateFormatter.display(proposal.appointmentAtUTC))
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Create") {
                onCreate(proposal)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
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
                        Text("Note must be 2048 characters or fewer.")
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
                        Text("Description must be 2048 characters or fewer.")
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
