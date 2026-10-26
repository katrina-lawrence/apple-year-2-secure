import Foundation

nonisolated struct AIPromptTemplates {
    let system: String
    let user: String
}

nonisolated enum AIPromptTemplateLoader {
    static func render(
        noteText: String,
        referenceDate: Date,
        bundle: Bundle = .main
    ) throws -> AIPromptTemplates {
        try render(
            noteText: noteText,
            referenceDate: referenceDate,
            systemTemplate: loadTemplate(named: "PromptSystem", bundle: bundle),
            userTemplate: loadTemplate(named: "PromptUser", bundle: bundle)
        )
    }

    static func render(
        noteText: String,
        referenceDate: Date,
        systemTemplate: String,
        userTemplate: String
    ) throws -> AIPromptTemplates {
        guard !systemTemplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIServiceError.emptyPromptResource("PromptSystem")
        }
        guard userTemplate.contains("{{referenceISO}}"), userTemplate.contains("{{noteText}}") else {
            throw AIServiceError.invalidUserTemplate
        }
        // Check the template before inserting untrusted note text. Literal braces
        // in a note must remain data rather than being treated as template syntax.
        let remaining = userTemplate
            .replacingOccurrences(of: "{{referenceISO}}", with: "")
            .replacingOccurrences(of: "{{noteText}}", with: "")
        guard !remaining.contains("{{"), !remaining.contains("}}") else {
            throw AIServiceError.invalidUserTemplate
        }
        let user = userTemplate
            .replacingOccurrences(of: "{{referenceISO}}", with: ISO8601DateFormatter().string(from: referenceDate))
            .replacingOccurrences(of: "{{noteText}}", with: noteText)
        return AIPromptTemplates(system: systemTemplate, user: user)
    }

    private static func loadTemplate(named name: String, bundle: Bundle) throws -> String {
        guard let url = bundle.url(forResource: name, withExtension: "md"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            throw AIServiceError.missingPromptResource(name)
        }
        return content
    }
}

nonisolated enum AIServiceError: LocalizedError {
    case missingPromptResource(String)
    case emptyPromptResource(String)
    case invalidUserTemplate

    var errorDescription: String? {
        switch self {
        case .missingPromptResource(let name):
            return "The app could not load \(name).md."
        case .emptyPromptResource(let name):
            return "\(name).md is empty."
        case .invalidUserTemplate:
            return "PromptUser.md must contain the noteText and referenceISO placeholders."
        }
    }
}
