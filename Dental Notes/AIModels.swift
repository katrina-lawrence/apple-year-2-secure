import Foundation

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
