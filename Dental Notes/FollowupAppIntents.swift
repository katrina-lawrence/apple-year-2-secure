import AppIntents
import SwiftData

private enum FollowupIntentConstants {
    static let customType = "Custom"
}

private enum FollowupIntentError: LocalizedError {
    case emptyDescription
    case serverCreationFailed(String?)
    case serverSyncFailed(String?)
    case followupFetchFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .emptyDescription:
            return "Followup description is required."
        case .serverCreationFailed(let message):
            return message ?? "Could not create followup."
        case .serverSyncFailed(let message):
            return message ?? "Could not refresh followups."
        case .followupFetchFailed:
            return "Could not read followups."
        case .saveFailed:
            return "Could not save followup."
        }
    }
}

private struct FollowupIntentDataStore {
    let container: ModelContainer
    let modelContext: ModelContext
}

private enum FollowupIntentModelContextFactory {
    static func makeStore() throws -> FollowupIntentDataStore {
        switch AppRuntimeMode.current {
        case .local:
            do {
                let container = try ModelContainer(for: NoteEntity.self, FollowupEntity.self)
                return FollowupIntentDataStore(container: container, modelContext: container.mainContext)
            } catch {
                Dental_NotesApp.purgeLocalSwiftDataStoreFiles()
                let container = try ModelContainer(for: NoteEntity.self, FollowupEntity.self)
                return FollowupIntentDataStore(container: container, modelContext: container.mainContext)
            }
        case .server:
            let schema = Schema([NoteEntity.self, FollowupEntity.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: configuration)
            return FollowupIntentDataStore(container: container, modelContext: container.mainContext)
        }
    }
}

private enum FollowupIntentQueries {
    static func nextIncompleteFollowup(in modelContext: ModelContext) throws -> FollowupEntity? {
        var descriptor = FetchDescriptor<FollowupEntity>(
            predicate: #Predicate<FollowupEntity> { !$0.isCompleted },
            sortBy: [SortDescriptor(\.createdAtUTC, order: .forward)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

struct CreateDentalFollowupIntent: AppIntent {
    static let title: LocalizedStringResource = "Create Dental Followup"
    static let description = IntentDescription("Create a followup that is not attached to a note.")
    static let openAppWhenRun = false

    @Parameter(
        title: "Followup Description",
        requestValueDialog: IntentDialog("What followup should I create?")
    )
    var descriptionText: String

    static var parameterSummary: some ParameterSummary {
        Summary("Create dental followup: \(\.$descriptionText)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty else {
            throw FollowupIntentError.emptyDescription
        }

        let dataStore = try FollowupIntentModelContextFactory.makeStore()
        let modelContext = dataStore.modelContext
        let now = Date()

        if AppRuntimeMode.current.isServer {
            let session = AppSessionViewModel()
            let success = await session.createFollowup(
                noteID: nil,
                type: FollowupIntentConstants.customType,
                descriptionText: trimmedDescription,
                modelContext: modelContext
            )
            guard success else {
                throw FollowupIntentError.serverCreationFailed(session.syncError)
            }
        } else {
            let followup = FollowupEntity(
                descriptionText: trimmedDescription,
                type: FollowupIntentConstants.customType,
                noteID: nil,
                createdAtUTC: now,
                editedAtUTC: now
            )
            modelContext.insert(followup)
            do {
                try modelContext.save()
            } catch {
                throw FollowupIntentError.saveFailed
            }
        }

        _ = dataStore.container
        return .result(dialog: "Followup created.")
    }
}

struct GetNextIncompleteFollowupIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Next Incomplete Followup"
    static let description = IntentDescription("Get the oldest incomplete followup.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let dataStore = try FollowupIntentModelContextFactory.makeStore()
        let modelContext = dataStore.modelContext

        if AppRuntimeMode.current.isServer {
            let session = AppSessionViewModel()
            let success = await session.refreshUserData(modelContext: modelContext)
            guard success else {
                throw FollowupIntentError.serverSyncFailed(session.syncError)
            }
        }

        let nextFollowup: FollowupEntity?
        do {
            nextFollowup = try FollowupIntentQueries.nextIncompleteFollowup(in: modelContext)
        } catch {
            throw FollowupIntentError.followupFetchFailed
        }

        _ = dataStore.container

        guard let nextFollowup else {
            return .result(value: "", dialog: "You have no incomplete followups.")
        }

        let value = nextFollowup.descriptionText
        return .result(value: value, dialog: IntentDialog(stringLiteral: value))
    }
}

struct DentalNotesAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateDentalFollowupIntent(),
            phrases: [
                "Create a dental followup in \(.applicationName)",
                "Add a dental followup in \(.applicationName)",
                "Create dental followup in \(.applicationName)",
                "Add dental followup in \(.applicationName)"
            ],
            shortTitle: "Create Followup",
            systemImageName: "calendar.badge.plus"
        )
        AppShortcut(
            intent: GetNextIncompleteFollowupIntent(),
            phrases: [
                "What is my next followup in \(.applicationName)",
                "Get my next followup in \(.applicationName)",
                "What is my next dental followup in \(.applicationName)",
                "Get next incomplete followup in \(.applicationName)"
            ],
            shortTitle: "Next Followup",
            systemImageName: "calendar"
        )
    }
}
