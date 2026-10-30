import AppIntents
import SwiftData

private enum FollowupIntentConstants {
    static let customType = "Custom"
}

private enum FollowupIntentError: LocalizedError {
    case emptyDescription
    case serverCreationFailed(String?)
    case serverSyncFailed(String?)
    case serverCompletionFailed(String?)
    case followupFetchFailed

    var errorDescription: String? {
        switch self {
        case .emptyDescription:
            return "Followup description is required."
        case .serverCreationFailed(let message):
            return message ?? "Could not create followup."
        case .serverSyncFailed(let message):
            return message ?? "Could not refresh followups."
        case .serverCompletionFailed(let message):
            return message ?? "Could not complete followup."
        case .followupFetchFailed:
            return "Could not read followups."
        }
    }
}

private struct FollowupIntentDataStore {
    let container: ModelContainer
    let modelContext: ModelContext
}

private enum FollowupIntentModelContextFactory {
    static func makeStore() throws -> FollowupIntentDataStore {
        let schema = Schema([NoteEntity.self, FollowupEntity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return FollowupIntentDataStore(container: container, modelContext: container.mainContext)
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
    static var authenticationPolicy: IntentAuthenticationPolicy {
        .requiresLocalDeviceAuthentication
    }

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
        let session = AppSessionViewModel()
        guard await session.createFollowupAndReturnID(
            noteID: nil,
            type: FollowupIntentConstants.customType,
            descriptionText: trimmedDescription,
            modelContext: dataStore.modelContext
        ) != nil else {
            throw FollowupIntentError.serverCreationFailed(session.syncError)
        }

        _ = dataStore.container
        return .result(dialog: "Followup created.")
    }
}

struct GetNextIncompleteFollowupIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Next Followup"
    static let description = IntentDescription("Get the oldest remaining followup.")
    static let openAppWhenRun = false
    static var authenticationPolicy: IntentAuthenticationPolicy {
        .requiresAuthentication
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let dataStore = try FollowupIntentModelContextFactory.makeStore()
        let session = AppSessionViewModel()

        let success = await session.refreshUserData(modelContext: dataStore.modelContext)
        guard success else {
            throw FollowupIntentError.serverSyncFailed(session.syncError)
        }

        let nextFollowup: FollowupEntity?
        do {
            nextFollowup = try FollowupIntentQueries.nextIncompleteFollowup(in: dataStore.modelContext)
        } catch {
            throw FollowupIntentError.followupFetchFailed
        }

        _ = dataStore.container

        guard let nextFollowup else {
            return .result(
                value: "",
                dialog: "You have no incomplete followups."
            )
        }

        let value = nextFollowup.descriptionText
        return .result(
            value: value,
            dialog: IntentDialog(stringLiteral: value)
        )
    }
}

struct CompleteNextFollowupIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Next Followup Done"
    static let description = IntentDescription("Mark the oldest incomplete followup as complete.")
    static let openAppWhenRun = false
    static var authenticationPolicy: IntentAuthenticationPolicy {
        .requiresAuthentication
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let dataStore = try FollowupIntentModelContextFactory.makeStore()
        let session = AppSessionViewModel()

        let syncSuccess = await session.refreshUserData(modelContext: dataStore.modelContext)
        guard syncSuccess else {
            throw FollowupIntentError.serverSyncFailed(session.syncError)
        }

        let nextFollowup: FollowupEntity?
        do {
            nextFollowup = try FollowupIntentQueries.nextIncompleteFollowup(in: dataStore.modelContext)
        } catch {
            throw FollowupIntentError.followupFetchFailed
        }

        guard let nextFollowup else {
            _ = dataStore.container
            return .result(
                value: "",
                dialog: "You have no incomplete followups."
            )
        }

        let completionSuccess = await session.setFollowupCompletion(
            followupID: nextFollowup.id,
            completed: true,
            modelContext: dataStore.modelContext
        )
        guard completionSuccess else {
            throw FollowupIntentError.serverCompletionFailed(session.syncError)
        }

        let value = "Complete: \(nextFollowup.descriptionText)"
        _ = dataStore.container
        return .result(
            value: value,
            dialog: IntentDialog(stringLiteral: value)
        )
    }
}

struct DentalNotesAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Keep query/read phrases separate from completion verbs to improve Siri intent disambiguation.
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
            intent: CompleteNextFollowupIntent(),
            phrases: [
                "\(.applicationName) Complete"
            ],
            shortTitle: "Mark Done",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: GetNextIncompleteFollowupIntent(),
            phrases: [
                "\(.applicationName) Display next"
            ],
            shortTitle: "Display Next",
            systemImageName: "calendar"
        )
    }
}
