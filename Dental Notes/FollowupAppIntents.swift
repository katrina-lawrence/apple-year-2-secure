import AppIntents
import SwiftData

struct CreateDentalFollowupIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Dental Follow-up"
    static var description = IntentDescription("Create a follow-up in My Dental Companion.")

    @Parameter(title: "Follow-up description", requestValueDialog: "What should the follow-up say?")
    var descriptionText: String

    // Leave the default device authentication policy for the first working version.
    // Review it during the security exercise in README-Day-2.md.

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // TODO: Trim and validate descriptionText (1 to 512 characters).
        // TODO: Make a context with FollowupIntentSupport.makeContext().
        // TODO: Create an AppSessionViewModel and use the signed-in account.
        // TODO: Call createFollowupAndReturnID(noteID:type:descriptionText:modelContext:).
        //       Use nil for noteID and "Custom" for type.
        // TODO: Handle failure. Return a success dialog only after creation succeeds.
        return .result(dialog: "Follow-up creation is not implemented yet.")
    }
}

@MainActor
enum FollowupIntentSupport {
    static func makeContext() throws -> ModelContext {
        let schema = Schema([NoteEntity.self, FollowupEntity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return ModelContext(container)
    }
}

struct DentalFollowupShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateDentalFollowupIntent(),
            phrases: [
                "Create a dental follow-up in \(.applicationName)",
                "Add a dental follow-up in \(.applicationName)"
            ],
            shortTitle: "Create Follow-up",
            systemImageName: "plus.circle"
        )
    }
}
