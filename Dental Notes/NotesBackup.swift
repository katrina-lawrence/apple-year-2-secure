import Foundation
import ZIPFoundation

struct NotesBackup: Codable {
    var formatVersion = 1
    let exportedAtUTC: Date
    let notes: [Note]
    let followups: [Followup]

    struct Note: Codable {
        let id: String
        let value: String
        let summary: String?
        let balanceDueAmount: Decimal?
        let balanceDueCurrency: String?
        let categories: [String]?
        let appointmentTiming: String?
        let createdAtUTC: Date
        let editedAtUTC: Date
    }

    struct Followup: Codable {
        let id: String
        let descriptionText: String
        let type: String
        let noteID: String?
        let createdAtUTC: Date
        let editedAtUTC: Date
        let isCompleted: Bool
    }

    func zipData() throws -> Data {
        let fileManager = FileManager.default
        let workingURL = fileManager.temporaryDirectory
            .appendingPathComponent("NotesBackup-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: workingURL, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: workingURL) }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let jsonURL = workingURL.appendingPathComponent("notes.json")
        try encoder.encode(self).write(to: jsonURL, options: .atomic)

        let zipURL = workingURL.appendingPathComponent("DentalNotes-Backup.zip")
        try fileManager.zipItem(at: jsonURL, to: zipURL)
        return try Data(contentsOf: zipURL)
    }
}
