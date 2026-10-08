import SwiftData
import SwiftUI

@main
struct Dental_NotesApp: App {
    var body: some Scene {
        WindowGroup {
            AppLockGateView()
        }
        .modelContainer(for: [NoteEntity.self, FollowupEntity.self])
    }
}
