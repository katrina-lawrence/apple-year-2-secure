import SwiftData
import SwiftUI

@main
struct Dental_NotesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [NoteEntity.self, FollowupEntity.self])
    }
}
