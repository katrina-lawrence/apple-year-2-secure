import SwiftData
import SwiftUI

@main
struct Dental_NotesApp: App {
    @StateObject private var appSession = AppSessionViewModel()
    @StateObject private var navigationCoordinator = AppNavigationCoordinator()

    private let sharedModelContainer: ModelContainer = {
        switch AppRuntimeMode.current {
        case .server:
            // SERVER_MODE keeps PHI in memory only.
            Dental_NotesApp.purgeLocalSwiftDataStoreFiles()
            do {
                let schema = Schema([NoteEntity.self, FollowupEntity.self])
                let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: configuration)
            } catch {
                fatalError("Could not initialize in-memory model container: \(error)")
            }
        case .local:
            do {
                return try ModelContainer(for: NoteEntity.self, FollowupEntity.self)
            } catch {
                Dental_NotesApp.purgeLocalSwiftDataStoreFiles()
                do {
                    return try ModelContainer(for: NoteEntity.self, FollowupEntity.self)
                } catch {
                    fatalError("Could not initialize model container after store reset: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppLockGateView()
                .environmentObject(appSession)
                .environmentObject(navigationCoordinator)
                .onOpenURL { url in
                    guard let route = AppDeepLinks.route(from: url) else { return }
                    navigationCoordinator.open(route: route)
                }
        }
        .modelContainer(sharedModelContainer)
    }

    static func purgeLocalSwiftDataStoreFiles() {
        let fileManager = FileManager.default
        guard let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }

        let bundleSubdirectory: URL
        if let bundleID = Bundle.main.bundleIdentifier, !bundleID.isEmpty {
            bundleSubdirectory = applicationSupportURL.appendingPathComponent(bundleID, isDirectory: true)
        } else {
            bundleSubdirectory = applicationSupportURL
        }

        let candidateDirectories = [bundleSubdirectory, applicationSupportURL]
        for directory in candidateDirectories {
            guard let contents = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
                continue
            }

            for url in contents {
                let filename = url.lastPathComponent.lowercased()
                let shouldDelete = filename.contains("default.store")
                    || filename.contains("model.sqlite")
                    || filename.hasSuffix(".store")
                    || filename.hasSuffix(".sqlite")
                    || filename.hasSuffix(".sqlite-shm")
                    || filename.hasSuffix(".sqlite-wal")
                if shouldDelete {
                    try? fileManager.removeItem(at: url)
                }
            }
        }
    }
}
