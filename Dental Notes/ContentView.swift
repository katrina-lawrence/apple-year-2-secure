import Foundation
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
    @Attribute(.unique) var id: String
    var value: String
    var summary: String?
    var balanceDueAmount: Decimal?
    var balanceDueCurrency: String?
    var categories: [String]?
    var appointmentTiming: String?
    var createdAtUTC: Date
    var editedAtUTC: Date

    init(
        id: String = UUID().uuidString,
        value: String,
        summary: String? = nil,
        balanceDueAmount: Decimal? = nil,
        balanceDueCurrency: String? = nil,
        categories: [String]? = nil,
        appointmentTiming: String? = nil,
        createdAtUTC: Date = Date(),
        editedAtUTC: Date = Date()
    ) {
        self.id = id
        self.value = value
        self.summary = summary
        self.balanceDueAmount = balanceDueAmount
        self.balanceDueCurrency = balanceDueCurrency
        self.categories = categories
        self.appointmentTiming = appointmentTiming
        self.createdAtUTC = createdAtUTC
        self.editedAtUTC = editedAtUTC
    }
}

@Model
final class FollowupEntity {
    @Attribute(.unique) var id: String
    var descriptionText: String
    var type: String
    var noteID: String
    var createdAtUTC: Date
    var editedAtUTC: Date
    var isCompleted: Bool

    init(
        id: String = UUID().uuidString,
        descriptionText: String,
        type: String,
        noteID: String,
        createdAtUTC: Date = Date(),
        editedAtUTC: Date = Date(),
        isCompleted: Bool = false
    ) {
        self.id = id
        self.descriptionText = descriptionText
        self.type = type
        self.noteID = noteID
        self.createdAtUTC = createdAtUTC
        self.editedAtUTC = editedAtUTC
        self.isCompleted = isCompleted
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

private enum CurrencyDisplayFormatter {
    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func format(amount: Decimal, currency: String?) -> String {
        let trimmedCurrency = currency?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let number = NSDecimalNumber(decimal: amount)

        if trimmedCurrency.count == 3, trimmedCurrency.unicodeScalars.allSatisfy(CharacterSet.letters.contains) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = trimmedCurrency.uppercased()
            if let value = formatter.string(from: number) {
                return value
            }
        }

        let amountText = decimalFormatter.string(from: number) ?? number.stringValue
        let symbol = trimmedCurrency.isEmpty ? "$" : trimmedCurrency
        return "\(symbol)\(amountText)"
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

struct ProposedFollowup: Identifiable, Hashable {
    let id: UUID
    let type: String
    let descriptionText: String

    init(id: UUID = UUID(), type: String, descriptionText: String) {
        self.id = id
        self.type = type
        self.descriptionText = descriptionText
    }
}

struct ProcessedNoteResult {
    let summary: String?
    let balanceDueAmount: Decimal?
    let balanceDueCurrency: String?
    let categories: [String]
    let appointmentTiming: String?
    let followups: [ProposedFollowup]
}

private struct ProcessedNotePreviewData {
    struct Followup: Identifiable {
        let id: UUID
        let type: String
        let descriptionText: String
    }

    let createdAtUTC: Date
    let editedAtUTC: Date
    let content: String
    let summary: String?
    let balanceDueAmount: Decimal?
    let balanceDueCurrency: String?
    let categories: [String]
    let appointmentTiming: String?
    let followups: [Followup]
}

private enum AIProviderMethod: String, CaseIterable, Identifiable {
    case appleIntelligence
    case thirdParty

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appleIntelligence:
            return "Apple Intelligence"
        case .thirdParty:
            return "Third-party provider"
        }
    }
}

private enum AppSettingsKeys {
    static let aiProviderMethod = "ai_provider_method"
}

private struct ThirdPartyAIConfig {
    var baseURL: String
    var modelID: String
    var apiKey: String?

    var isValid: Bool {
        !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct ThirdPartyAIConfigFile: Decodable {
    let endpoint: String?
    let model: String?
    let apiKey: String?

    private func nonEmptyTrimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var trimmedEndpoint: String? { nonEmptyTrimmed(endpoint) }
    var trimmedModel: String? { nonEmptyTrimmed(model) }
    var trimmedAPIKey: String? { nonEmptyTrimmed(apiKey) }
}

private enum AppSettingsStore {
    private static let thirdPartyConfigResourceName = "ThirdPartyAIConfig"
    private static let thirdPartyConfigExtension = "plist"

    static func currentProvider(rawValue: String) -> AIProviderMethod {
        AIProviderMethod(rawValue: rawValue) ?? .appleIntelligence
    }

    static func thirdPartyConfig() -> ThirdPartyAIConfig {
        let fileConfig = bundledThirdPartyConfig()
        let fileEndpoint = fileConfig?.trimmedEndpoint
        let fileModel = fileConfig?.trimmedModel
        let fileAPIKey = fileConfig?.trimmedAPIKey

        return ThirdPartyAIConfig(
            baseURL: fileEndpoint ?? "",
            modelID: fileModel ?? "",
            apiKey: fileAPIKey
        )
    }

    private static func bundledThirdPartyConfig() -> ThirdPartyAIConfigFile? {
        guard let url = Bundle.main.url(
            forResource: thirdPartyConfigResourceName,
            withExtension: thirdPartyConfigExtension
        ) else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? PropertyListDecoder().decode(ThirdPartyAIConfigFile.self, from: data)
    }
}

#if canImport(FoundationModels)
@Generable
private struct AIActionDraft {
    var type: String
    var description: String
}

@Generable
private struct AIBalanceDueDraft {
    var amount: Double?
    var currency: String?
}

@Generable
private struct AIProcessedNoteDraft {
    var summary: String
    var categories: [String]
    var balance_due: AIBalanceDueDraft?
    var actions: [AIActionDraft]
    var appointment_timing: String?
}

private enum AIServiceError: Error {
    case unsupportedProvider
    case invalidConfiguration
    case invalidURL
    case invalidResponse
    case badHTTPStatus(Int)
    case decodingFailed
    case missingPromptResource(String)
    case unreadablePromptResource(String)
    case emptyPromptResource(String)
    case unresolvedPromptPlaceholders
}

private struct ThirdPartyAnthropicMessagesRequest: Encodable {
    struct Message: Encodable {
        struct ContentBlock: Encodable {
            let type: String
            let text: String
        }

        let role: String
        let content: [ContentBlock]
    }

    let model: String
    let max_tokens: Int
    let system: String
    let messages: [Message]
}

private struct ThirdPartyAnthropicMessagesResponse: Decodable {
    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }

    let content: [ContentBlock]
}

private struct ThirdPartyAIActionDraft: Decodable {
    let type: String?
    let description: String?
}

private struct ThirdPartyAIProcessedNoteDraft: Decodable {
    let summary: String?
    let balance_due: ThirdPartyAIBalanceDueDraft?
    let categories: [String]?
    let actions: [ThirdPartyAIActionDraft]?
    let appointment_timing: String?
}

private struct ThirdPartyAIBalanceDueDraft: Decodable {
    let amount: Double?
    let currency: String?
}

private struct AIPromptTemplates {
    let system: String
    let user: String
}

private enum AIPromptTemplateLoader {
    private static let systemTemplateName = "PromptSystem"
    private static let userTemplateName = "PromptUser"
    private static let placeholderReferenceISO = "{{referenceISO}}"
    private static let placeholderNoteText = "{{noteText}}"

    static func render(noteText: String, referenceDate: Date) throws -> AIPromptTemplates {
        let system = try loadTemplate(named: systemTemplateName)
        let userTemplate = try loadTemplate(named: userTemplateName)

        let referenceISO = ISO8601DateFormatter().string(from: referenceDate)
        let user = userTemplate
            .replacingOccurrences(of: placeholderReferenceISO, with: referenceISO)
            .replacingOccurrences(of: placeholderNoteText, with: noteText)

        if user.contains("{{") || user.contains("}}") {
            throw AIServiceError.unresolvedPromptPlaceholders
        }

        return AIPromptTemplates(system: system, user: user)
    }

    private static func loadTemplate(named resourceName: String) throws -> String {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "md") else {
            throw AIServiceError.missingPromptResource(resourceName)
        }
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            throw AIServiceError.unreadablePromptResource(resourceName)
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AIServiceError.emptyPromptResource(resourceName)
        }
        return trimmed
    }
}

private enum NoteFollowupAIService {
    static func isAppleAvailable() -> Bool {
        switch SystemLanguageModel.default.availability {
        case .available:
            return true
        case .unavailable:
            return false
        @unknown default:
            return false
        }
    }

    static func processNote(
        from noteText: String,
        referenceDate: Date,
        provider: AIProviderMethod,
        thirdPartyConfig: ThirdPartyAIConfig?
    ) async throws -> ProcessedNoteResult {
        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNote.isEmpty else {
            return ProcessedNoteResult(
                summary: nil,
                balanceDueAmount: nil,
                balanceDueCurrency: nil,
                categories: [],
                appointmentTiming: nil,
                followups: []
            )
        }

        let draft: AIProcessedNoteDraft
        switch provider {
        case .appleIntelligence:
            draft = try await processNoteWithApple(noteText: trimmedNote, referenceDate: referenceDate)
        case .thirdParty:
            guard let config = thirdPartyConfig, config.isValid else {
                throw AIServiceError.invalidConfiguration
            }
            draft = try await processNoteWithThirdParty(noteText: trimmedNote, referenceDate: referenceDate, config: config)
        }

        return normalizeProcessedResult(from: draft)
    }

    private static func normalizeProcessedResult(from draft: AIProcessedNoteDraft) -> ProcessedNoteResult {
        let followups: [ProposedFollowup] = draft.actions.prefix(8).compactMap { actionDraft -> ProposedFollowup? in
            let type = actionDraft.type.trimmingCharacters(in: .whitespacesAndNewlines)
            let description = actionDraft.description.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !type.isEmpty else { return nil }
            guard !description.isEmpty else { return nil }
            return ProposedFollowup(type: type, descriptionText: description)
        }

        let summary = trimmedOrNil(draft.summary)
        let amount: Decimal?
        if let balance = draft.balance_due?.amount {
            amount = NSDecimalNumber(value: balance).decimalValue
        } else {
            amount = nil
        }
        let currency = amount == nil ? nil : normalizedCurrency(draft.balance_due?.currency)

        var seenCategories = Set<String>()
        let categories = (draft.categories)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seenCategories.insert($0.lowercased()).inserted }

        return ProcessedNoteResult(
            summary: summary,
            balanceDueAmount: amount,
            balanceDueCurrency: currency,
            categories: categories,
            appointmentTiming: trimmedOrNil(draft.appointment_timing),
            followups: followups
        )
    }

    private static func processNoteWithApple(noteText: String, referenceDate: Date) async throws -> AIProcessedNoteDraft {
        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNote.isEmpty else {
            return AIProcessedNoteDraft(
                summary: "",
                categories: [],
                balance_due: nil,
                actions: [],
                appointment_timing: nil
            )
        }

        let prompts = try AIPromptTemplateLoader.render(noteText: trimmedNote, referenceDate: referenceDate)
        let session = LanguageModelSession(instructions: prompts.system)

        let response = try await session.respond(to: prompts.user, generating: AIProcessedNoteDraft.self)
        return response.content
    }

    private static func processNoteWithThirdParty(
        noteText: String,
        referenceDate: Date,
        config: ThirdPartyAIConfig
    ) async throws -> AIProcessedNoteDraft {
        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNote.isEmpty else {
            return AIProcessedNoteDraft(
                summary: "",
                categories: [],
                balance_due: nil,
                actions: [],
                appointment_timing: nil
            )
        }

        guard let endpoint = anthropicMessagesURL(from: config.baseURL) else {
            throw AIServiceError.invalidURL
        }

        let prompts = try AIPromptTemplateLoader.render(noteText: trimmedNote, referenceDate: referenceDate)

        let requestBody = ThirdPartyAnthropicMessagesRequest(
            model: config.modelID,
            max_tokens: 1200,
            system: prompts.system,
            messages: [
                .init(
                    role: "user",
                    content: [
                        .init(type: "text", text: prompts.user)
                    ]
                )
            ]
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        if let apiKey = config.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines), !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        }
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw AIServiceError.badHTTPStatus(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(ThirdPartyAnthropicMessagesResponse.self, from: data)
        let content = decoded.content
            .filter { $0.type == "text" }
            .compactMap(\.text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else {
            throw AIServiceError.invalidResponse
        }

        let cleaned = cleanedJSONText(from: content)
        guard let contentData = cleaned.data(using: .utf8),
              let thirdPartyDraftList = try? JSONDecoder().decode(ThirdPartyAIProcessedNoteDraft.self, from: contentData) else {
            throw AIServiceError.decodingFailed
        }

        return AIProcessedNoteDraft(
            summary: thirdPartyDraftList.summary ?? "",
            categories: thirdPartyDraftList.categories ?? [],
            balance_due: thirdPartyDraftList.balance_due.map {
                AIBalanceDueDraft(amount: $0.amount, currency: $0.currency)
            },
            actions: (thirdPartyDraftList.actions ?? []).compactMap { action in
                guard let type = action.type, let description = action.description else { return nil }
                return AIActionDraft(
                    type: type,
                    description: description
                )
            },
            appointment_timing: thirdPartyDraftList.appointment_timing
        )
    }

    private static func anthropicMessagesURL(from baseURL: String) -> URL? {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var url = URL(string: trimmed) else { return nil }

        if url.path.hasSuffix("/messages") {
            return url
        }
        if url.path.hasSuffix("/v1") {
            url.append(path: "messages")
            return url
        }
        if url.path.isEmpty || url.path == "/" {
            url.append(path: "v1/messages")
            return url
        }

        url.append(path: "messages")
        return url
    }

    private static func cleanedJSONText(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("```") else { return trimmed }

        var lines = trimmed.components(separatedBy: .newlines)
        if !lines.isEmpty {
            lines.removeFirst()
        }
        if let last = lines.last,
           last.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("```") {
            lines.removeLast()
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func trimmedOrNil(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func normalizedCurrency(_ value: String?) -> String? {
        guard let trimmed = trimmedOrNil(value) else { return nil }
        return trimmed.uppercased()
    }
}
#else
private enum AIServiceError: Error {
    case unsupportedProvider
    case invalidConfiguration
}

private enum NoteFollowupAIService {
    static func isAppleAvailable() -> Bool { false }

    static func processNote(
        from noteText: String,
        referenceDate: Date,
        provider: AIProviderMethod,
        thirdPartyConfig: ThirdPartyAIConfig?
    ) async throws -> ProcessedNoteResult {
        let _ = noteText
        let _ = referenceDate
        let _ = thirdPartyConfig
        switch provider {
        case .appleIntelligence:
            throw AIServiceError.unsupportedProvider
        case .thirdParty:
            throw AIServiceError.unsupportedProvider
        }
    }
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
    @EnvironmentObject private var session: AppSessionViewModel
    @Query(sort: \NoteEntity.createdAtUTC, order: .reverse) private var notes: [NoteEntity]
    @Query private var allFollowups: [FollowupEntity]

    @State private var showingCreateNote = false
    @State private var showingSettings = false
    @State private var notePendingDelete: NoteEntity?
    @State private var operationError: String?

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
            .refreshable {
                if session.mode.isServer {
                    _ = await session.refreshUserData(modelContext: modelContext)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
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
            .sheet(isPresented: $showingSettings) {
                SettingsView()
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
                    Task { @MainActor in
                        await deleteNoteWithFollowups(note)
                    }
                    notePendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    notePendingDelete = nil
                }
            } message: {
                Text("This also deletes all followups associated with this note.")
            }
            .alert("Sync Error", isPresented: Binding(
                get: { operationError != nil || session.syncError != nil },
                set: { newValue in
                    if !newValue {
                        operationError = nil
                        session.clearSyncError()
                    }
                })
            ) {
                Button("OK", role: .cancel) {
                    operationError = nil
                    session.clearSyncError()
                }
            } message: {
                Text(operationError ?? session.syncError ?? "Request failed.")
            }
        }
    }

    private func deleteNoteWithFollowups(_ note: NoteEntity) async {
        if session.mode.isServer {
            let success = await session.deleteNote(noteID: note.id, modelContext: modelContext)
            if !success {
                operationError = session.syncError ?? "Could not delete note."
            }
            return
        }

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
    @EnvironmentObject private var session: AppSessionViewModel
    @Query(sort: \FollowupEntity.createdAtUTC, order: .reverse) private var followups: [FollowupEntity]

    @State private var hideCompleted = false
    @State private var followupPendingDelete: FollowupEntity?
    @State private var operationError: String?

    private var displayedFollowups: [FollowupEntity] {
        hideCompleted ? followups.filter { !$0.isCompleted } : followups
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
                                Text(followup.type.preview())
                                    .fontWeight(.semibold)
                                Text(followup.descriptionText.preview())
                                    .foregroundStyle(followup.isCompleted ? .secondary : .primary)
                                    .strikethrough(followup.isCompleted)
                            }
                            .opacity(followup.isCompleted ? 0.65 : 1)
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
            .refreshable {
                if session.mode.isServer {
                    _ = await session.refreshUserData(modelContext: modelContext)
                }
            }
            .alert("Delete Followup?", isPresented: Binding(get: {
                followupPendingDelete != nil
            }, set: { newValue in
                if !newValue {
                    followupPendingDelete = nil
                }
            })) {
                Button("Delete", role: .destructive) {
                    guard let followup = followupPendingDelete else { return }
                    Task { @MainActor in
                        await deleteFollowup(followup)
                    }
                    followupPendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    followupPendingDelete = nil
                }
            }
            .alert("Sync Error", isPresented: Binding(
                get: { operationError != nil || session.syncError != nil },
                set: { newValue in
                    if !newValue {
                        operationError = nil
                        session.clearSyncError()
                    }
                })
            ) {
                Button("OK", role: .cancel) {
                    operationError = nil
                    session.clearSyncError()
                }
            } message: {
                Text(operationError ?? session.syncError ?? "Request failed.")
            }
        }
    }

    private func deleteFollowup(_ followup: FollowupEntity) async {
        if session.mode.isServer {
            let success = await session.deleteFollowup(followupID: followup.id, modelContext: modelContext)
            if !success {
                operationError = session.syncError ?? "Could not delete followup."
            }
            return
        }

        modelContext.delete(followup)
        try? modelContext.save()
    }
}

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var session: AppSessionViewModel

    @AppStorage(AppSettingsKeys.aiProviderMethod) private var providerMethodRawValue = AIProviderMethod.appleIntelligence.rawValue
    @State private var confirmingLogout = false

    private var selectedProvider: AIProviderMethod {
        AppSettingsStore.currentProvider(rawValue: providerMethodRawValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("AI Method") {
                    Picker("Provider", selection: Binding(
                        get: { selectedProvider },
                        set: { newValue in
                            providerMethodRawValue = newValue.rawValue
                        })
                    ) {
                        ForEach(AIProviderMethod.allCases) { method in
                            Text(method.title).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if session.mode.isServer && session.isAuthenticated {
                    Section("Account") {
                        Button("Log Out", role: .destructive) {
                            confirmingLogout = true
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Log Out?", isPresented: $confirmingLogout) {
                Button("Log Out", role: .destructive) {
                    Task { @MainActor in
                        await session.logoutAndClearLocalData(modelContext: modelContext)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes local notes and followups from this device.")
            }
        }
    }
}

private struct NoteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var session: AppSessionViewModel

    @AppStorage(AppSettingsKeys.aiProviderMethod) private var providerMethodRawValue = AIProviderMethod.appleIntelligence.rawValue

    let note: NoteEntity

    @Query(sort: \FollowupEntity.createdAtUTC, order: .reverse) private var allFollowups: [FollowupEntity]

    @State private var showingEditNote = false
    @State private var notePendingDelete = false
    @State private var aiAvailable = false
    @State private var isProcessingWithAI = false
    @State private var aiProcessError: String?
    @State private var aiHasProcessed = false
    @State private var proposedFollowups: [ProposedFollowup] = []
    @State private var pendingProcessedResult: ProcessedNoteResult?
    @State private var pendingProcessedEditedAtUTC: Date?
    @State private var showingProcessApproval = false
    @State private var isSavingProcessedNote = false

    private var associatedFollowups: [FollowupEntity] {
        allFollowups.filter { $0.noteID == note.id }
    }

    private var selectedProvider: AIProviderMethod {
        AppSettingsStore.currentProvider(rawValue: providerMethodRawValue)
    }

    private var thirdPartyConfig: ThirdPartyAIConfig {
        AppSettingsStore.thirdPartyConfig()
    }

    private var canProcessWithCurrentProvider: Bool {
        switch selectedProvider {
        case .appleIntelligence:
            return aiAvailable
        case .thirdParty:
            return thirdPartyConfig.isValid
        }
    }

    private var pendingPreviewData: ProcessedNotePreviewData? {
        guard let pendingProcessedResult else { return nil }
        let stagedEditedAtUTC = pendingProcessedEditedAtUTC ?? Date()
        return ProcessedNotePreviewData(
            createdAtUTC: note.createdAtUTC,
            editedAtUTC: stagedEditedAtUTC,
            content: note.value,
            summary: pendingProcessedResult.summary,
            balanceDueAmount: pendingProcessedResult.balanceDueAmount,
            balanceDueCurrency: pendingProcessedResult.balanceDueCurrency,
            categories: pendingProcessedResult.categories,
            appointmentTiming: pendingProcessedResult.appointmentTiming,
            followups: pendingProcessedResult.followups.map { proposal in
                ProcessedNotePreviewData.Followup(
                    id: proposal.id,
                    type: proposal.type,
                    descriptionText: proposal.descriptionText
                )
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
        .alert("Delete Note?", isPresented: $notePendingDelete) {
            Button("Delete", role: .destructive) {
                Task { @MainActor in
                    await deleteCurrentNote()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This also deletes all followups associated with this note.")
        }
        .fullScreenCover(isPresented: $showingProcessApproval) {
            if let pendingPreviewData {
                ProcessedNoteApprovalPreview(
                    preview: pendingPreviewData,
                    isSaving: isSavingProcessedNote,
                    onSave: applyPendingProcessedChanges,
                    onCancel: discardPendingProcessedChanges
                )
            } else {
                EmptyView()
            }
        }
        .onAppear {
            aiAvailable = NoteFollowupAIService.isAppleAvailable()
        }
        .alert("Sync Error", isPresented: Binding(
            get: { session.syncError != nil },
            set: { newValue in
                if !newValue {
                    session.clearSyncError()
                }
            })
        ) {
            Button("OK", role: .cancel) {
                session.clearSyncError()
            }
        } message: {
            Text(session.syncError ?? "Request failed.")
        }
    }

    private var followupsSection: some View {
        Section("Followups") {
            ExistingFollowupsList(followups: associatedFollowups)

            AIProcessingControls(
                canProcess: canProcessWithCurrentProvider,
                isProcessingWithAI: isProcessingWithAI,
                aiProcessError: aiProcessError,
                aiHasProcessed: aiHasProcessed,
                proposedFollowups: proposedFollowups,
                onProcess: processWithAI
            )
        }
    }

    private func processWithAI() {
        guard !isProcessingWithAI else { return }

        isProcessingWithAI = true
        aiProcessError = nil
        aiHasProcessed = false
        proposedFollowups = []

        Task { @MainActor in
            do {
                let processed = try await NoteFollowupAIService.processNote(
                    from: note.value,
                    referenceDate: note.createdAtUTC,
                    provider: selectedProvider,
                    thirdPartyConfig: selectedProvider == .thirdParty ? thirdPartyConfig : nil
                )
                await MainActor.run {
                    pendingProcessedResult = processed
                    pendingProcessedEditedAtUTC = Date()
                    showingProcessApproval = true
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

    private func applyPendingProcessedChanges() {
        guard let processed = pendingProcessedResult else { return }
        isSavingProcessedNote = true

        Task { @MainActor in
            if session.mode.isServer {
                let success = await session.saveProcessedNote(note: note, result: processed, modelContext: modelContext)
                await MainActor.run {
                    if success {
                        proposedFollowups = processed.followups
                        aiHasProcessed = true
                        pendingProcessedResult = nil
                        pendingProcessedEditedAtUTC = nil
                        showingProcessApproval = false
                    }
                    isSavingProcessedNote = false
                }
                return
            }

            let editedAtUTC = pendingProcessedEditedAtUTC ?? Date()
            await MainActor.run {
                applyProcessedNoteResult(processed, editedAtUTC: editedAtUTC)
                replaceFollowups(with: processed.followups)
                proposedFollowups = processed.followups
                aiHasProcessed = true
                try? modelContext.save()
                pendingProcessedResult = nil
                pendingProcessedEditedAtUTC = nil
                showingProcessApproval = false
                isSavingProcessedNote = false
            }
        }
    }

    private func discardPendingProcessedChanges() {
        pendingProcessedResult = nil
        pendingProcessedEditedAtUTC = nil
        showingProcessApproval = false
        aiHasProcessed = false
        proposedFollowups = []
    }

    private func replaceFollowups(with followups: [ProposedFollowup]) {
        for followup in associatedFollowups {
            modelContext.delete(followup)
        }

        let now = Date()
        for proposal in followups {
            let followup = FollowupEntity(
                descriptionText: proposal.descriptionText,
                type: proposal.type,
                noteID: note.id,
                createdAtUTC: now,
                editedAtUTC: now
            )
            modelContext.insert(followup)
        }
    }

    private func applyProcessedNoteResult(_ result: ProcessedNoteResult, editedAtUTC: Date) {
        note.summary = result.summary
        note.balanceDueAmount = result.balanceDueAmount
        note.balanceDueCurrency = result.balanceDueCurrency
        note.categories = result.categories
        note.appointmentTiming = result.appointmentTiming
        note.editedAtUTC = editedAtUTC
    }

    private func deleteCurrentNote() async {
        if session.mode.isServer {
            let success = await session.deleteNote(noteID: note.id, modelContext: modelContext)
            if success {
                dismiss()
            }
            return
        }

        for followup in associatedFollowups {
            modelContext.delete(followup)
        }
        modelContext.delete(note)
        try? modelContext.save()
        dismiss()
    }
}

private struct NoteMetadataSection: View {
    let note: NoteEntity

    private var trimmedSummary: String? {
        let value = note.summary?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    private var trimmedAppointmentTiming: String? {
        let value = note.appointmentTiming?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    private var normalizedCategories: [String] {
        (note.categories ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var formattedBalance: String? {
        guard let amount = note.balanceDueAmount else { return nil }
        return CurrencyDisplayFormatter.format(amount: amount, currency: note.balanceDueCurrency)
    }

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

            if let summary = trimmedSummary {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summary)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
            }

            if let formattedBalance {
                LabeledContent("Balance Due") {
                    Text(formattedBalance)
                        .multilineTextAlignment(.trailing)
                }
            }

            if !normalizedCategories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Categories")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(normalizedCategories.joined(separator: ", "))
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
            }

            if let appointmentTiming = trimmedAppointmentTiming {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appointment Timing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(appointmentTiming)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
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
                        Text(followup.type.preview())
                            .fontWeight(.semibold)
                        Text(followup.descriptionText.preview())
                            .foregroundStyle(followup.isCompleted ? .secondary : .primary)
                            .strikethrough(followup.isCompleted)
                    }
                    .opacity(followup.isCompleted ? 0.65 : 1)
                }
            }
        }
    }
}

private struct AIProcessingControls: View {
    let canProcess: Bool
    let isProcessingWithAI: Bool
    let aiProcessError: String?
    let aiHasProcessed: Bool
    let proposedFollowups: [ProposedFollowup]
    let onProcess: () -> Void

    var body: some View {
        if canProcess {
            Button {
                onProcess()
            } label: {
                Label("Process Note", systemImage: "wand.and.stars")
            }
            .disabled(isProcessingWithAI)

            if isProcessingWithAI {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Processing note…")
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
        }
    }
}

private struct ProcessedNoteApprovalPreview: View {
    let preview: ProcessedNotePreviewData
    let isSaving: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ProcessedNoteMetadataSection(preview: preview)
                Section("Followups") {
                    ProcessedFollowupsPreviewList(followups: preview.followups)
                }
            }
            .navigationTitle("Review Processed Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

private struct ProcessedNoteMetadataSection: View {
    let preview: ProcessedNotePreviewData

    private var trimmedSummary: String? {
        let value = preview.summary?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    private var trimmedAppointmentTiming: String? {
        let value = preview.appointmentTiming?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    private var normalizedCategories: [String] {
        preview.categories
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var formattedBalance: String? {
        guard let amount = preview.balanceDueAmount else { return nil }
        return CurrencyDisplayFormatter.format(amount: amount, currency: preview.balanceDueCurrency)
    }

    var body: some View {
        Section("Note") {
            LabeledContent("Created") {
                Text(AppDateFormatter.display(preview.createdAtUTC))
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent("Edited") {
                Text(AppDateFormatter.display(preview.editedAtUTC))
                    .multilineTextAlignment(.trailing)
            }

            if let summary = trimmedSummary {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summary)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
            }

            if let formattedBalance {
                LabeledContent("Balance Due") {
                    Text(formattedBalance)
                        .multilineTextAlignment(.trailing)
                }
            }

            if !normalizedCategories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Categories")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(normalizedCategories.joined(separator: ", "))
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
            }

            if let appointmentTiming = trimmedAppointmentTiming {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appointment Timing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(appointmentTiming)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(preview.content.isEmpty ? "(Empty)" : preview.content)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 4)
        }
    }
}

private struct ProcessedFollowupsPreviewList: View {
    let followups: [ProcessedNotePreviewData.Followup]

    var body: some View {
        if followups.isEmpty {
            Text("No followups for this note.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(followups) { followup in
                VStack(alignment: .leading, spacing: 4) {
                    Text(followup.type.preview())
                        .fontWeight(.semibold)
                    Text(followup.descriptionText.preview())
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct FollowupDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var session: AppSessionViewModel

    let followup: FollowupEntity

    @Query private var notes: [NoteEntity]

    @State private var showingEditFollowup = false
    @State private var followupPendingDelete = false

    private var associatedNote: NoteEntity? {
        notes.first { $0.id == followup.noteID }
    }

    private var trimmedType: String? {
        let value = followup.type.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var body: some View {
        List {
            Section("Followup") {
                LabeledContent("Created") {
                    Text(AppDateFormatter.display(followup.createdAtUTC))
                }
                LabeledContent("Edited") {
                    Text(AppDateFormatter.display(followup.editedAtUTC))
                }
                LabeledContent("Completed") {
                    Text(followup.isCompleted ? "Yes" : "No")
                }

                if let type = trimmedType {
                    LabeledContent("Type") {
                        Text(type)
                            .multilineTextAlignment(.trailing)
                    }
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
                    setCompleted(to: !followup.isCompleted)
                } label: {
                    Label(
                        followup.isCompleted ? "Mark Incomplete" : "Mark Completed",
                        systemImage: followup.isCompleted ? "xmark.circle" : "checkmark.circle"
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
                Task { @MainActor in
                    await deleteFollowup()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func setCompleted(to completed: Bool) {
        if session.mode.isServer {
            Task { @MainActor in
                _ = await session.setFollowupCompletion(
                    followupID: followup.id,
                    completed: completed,
                    modelContext: modelContext
                )
            }
            return
        }

        followup.isCompleted = completed
        followup.editedAtUTC = Date()
        try? modelContext.save()
    }

    private func deleteFollowup() async {
        if session.mode.isServer {
            let success = await session.deleteFollowup(followupID: followup.id, modelContext: modelContext)
            if success {
                dismiss()
            }
            return
        }

        modelContext.delete(followup)
        try? modelContext.save()
        dismiss()
    }
}

private struct NoteEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var session: AppSessionViewModel

    let note: NoteEntity?

    @State private var value: String
    @State private var isSaving = false
    @State private var saveError: String?

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
                    .disabled(isTooLong || isSaving)
                }
            }
            .alert("Save Error", isPresented: Binding(get: {
                saveError != nil
            }, set: { newValue in
                if !newValue { saveError = nil }
            })) {
                Button("OK", role: .cancel) {
                    saveError = nil
                }
            } message: {
                Text(saveError ?? "Could not save note.")
            }
        }
    }

    private func save() {
        if isSaving { return }
        isSaving = true
        saveError = nil

        if session.mode.isServer {
            let noteValue = value
            Task { @MainActor in
                let success: Bool
                if let note {
                    success = await session.updateNote(noteID: note.id, value: noteValue, modelContext: modelContext)
                } else {
                    success = await session.createNote(value: noteValue, modelContext: modelContext)
                }

                await MainActor.run {
                    isSaving = false
                    if success {
                        dismiss()
                    } else {
                        saveError = session.syncError ?? "Could not save note."
                    }
                }
            }
            return
        }

        let now = Date()
        if let note {
            note.value = value
            note.editedAtUTC = now
        } else {
            let created = NoteEntity(value: value, createdAtUTC: now, editedAtUTC: now)
            modelContext.insert(created)
        }

        try? modelContext.save()
        isSaving = false
        dismiss()
    }
}

private struct FollowupEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var session: AppSessionViewModel

    let noteID: String
    let existingFollowup: FollowupEntity?

    @State private var typeText: String
    @State private var descriptionText: String
    @State private var isSaving = false
    @State private var saveError: String?

    init(noteID: String? = nil, existingFollowup: FollowupEntity? = nil) {
        let resolvedNoteID = noteID ?? existingFollowup?.noteID ?? UUID().uuidString
        self.noteID = resolvedNoteID
        self.existingFollowup = existingFollowup
        _typeText = State(initialValue: existingFollowup?.type ?? "")
        _descriptionText = State(initialValue: existingFollowup?.descriptionText ?? "")
    }

    private var isDescriptionTooLong: Bool {
        descriptionText.count > TextLimits.maxLength
    }

    private var isTypeTooLong: Bool {
        typeText.count > TextLimits.maxLength
    }

    private var isTypeEmpty: Bool {
        typeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    TextField("Type", text: $typeText)
                    HStack {
                        Spacer()
                        Text("\(typeText.count)/\(TextLimits.maxLength)")
                            .font(.caption)
                            .foregroundStyle((isTypeTooLong || isTypeEmpty) ? .red : .secondary)
                    }
                    if isTypeEmpty {
                        Text("Type is required.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if isTypeTooLong {
                        Text("Type must be 2048 characters or fewer.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Description") {
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 180)
                    HStack {
                        Spacer()
                        Text("\(descriptionText.count)/\(TextLimits.maxLength)")
                            .font(.caption)
                            .foregroundStyle(isDescriptionTooLong ? .red : .secondary)
                    }
                    if isDescriptionTooLong {
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
                    .disabled(isDescriptionTooLong || isTypeTooLong || isTypeEmpty || isSaving)
                }
            }
            .alert("Save Error", isPresented: Binding(get: {
                saveError != nil
            }, set: { newValue in
                if !newValue { saveError = nil }
            })) {
                Button("OK", role: .cancel) {
                    saveError = nil
                }
            } message: {
                Text(saveError ?? "Could not save followup.")
            }
        }
    }

    private func save() {
        if isSaving { return }
        isSaving = true
        saveError = nil

        let now = Date()
        let trimmedType = typeText.trimmingCharacters(in: .whitespacesAndNewlines)

        if session.mode.isServer {
            let description = descriptionText
            Task { @MainActor in
                let success: Bool
                if let existingFollowup {
                    success = await session.updateFollowupText(
                        followup: existingFollowup,
                        type: trimmedType,
                        descriptionText: description,
                        modelContext: modelContext
                    )
                } else {
                    success = await session.createFollowup(
                        noteID: noteID,
                        type: trimmedType,
                        descriptionText: description,
                        modelContext: modelContext
                    )
                }

                await MainActor.run {
                    isSaving = false
                    if success {
                        dismiss()
                    } else {
                        saveError = session.syncError ?? "Could not save followup."
                    }
                }
            }
            return
        }

        if let existingFollowup {
            existingFollowup.type = trimmedType
            existingFollowup.descriptionText = descriptionText
            existingFollowup.editedAtUTC = now
        } else {
            let followup = FollowupEntity(
                descriptionText: descriptionText,
                type: trimmedType,
                noteID: noteID,
                createdAtUTC: now,
                editedAtUTC: now
            )
            modelContext.insert(followup)
        }

        try? modelContext.save()
        isSaving = false
        dismiss()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [NoteEntity.self, FollowupEntity.self], inMemory: true)
        .environmentObject(AppSessionViewModel())
}
