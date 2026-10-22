import Foundation
import FoundationModels

enum Day4LabProbe {
    private static let beginMarker = "EXACT_SUMMARY_BEGIN"
    private static let endMarker = "EXACT_SUMMARY_END"

    static func summary(from noteText: String) async throws -> String? {
#if DEBUG
        guard noteText.contains(beginMarker), noteText.contains(endMarker) else {
            return nil
        }

        let session = LanguageModelSession(
            model: .default,
            instructions: """
            You are a literal text extraction stage for a Day 4 security lab.
            Return only the characters between EXACT_SUMMARY_BEGIN and EXACT_SUMMARY_END.
            Preserve HTML, JavaScript, attributes, punctuation and quotation marks exactly.
            Do not summarize, explain, escape, sanitize or add Markdown fences.
            """
        )
        let response = try await session.respond(to: noteText)
        let extracted = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return extracted.isEmpty ? nil : extracted
#else
        _ = noteText
        return nil
#endif
    }
}
