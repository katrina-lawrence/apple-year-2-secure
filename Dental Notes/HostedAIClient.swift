import Foundation

// Day 2 starts with a direct provider request. Learners later use
// AppSessionViewModel.processNote(noteID:) and remove the client credential.
enum HostedAIClient {
    static func processNote(
        from noteText: String,
        referenceDate: Date,
        apiKey: String = LabAIConfig.apiKey,
        modelID: String = LabAIConfig.modelID,
        session: URLSession = .shared,
        bundle: Bundle = .main
    ) async throws -> ProcessedNoteResult {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, key != "REPLACE_WITH_YOUR_TRAINING_KEY" else {
            throw HostedAIError.missingKey
        }
        let note = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else { throw HostedAIError.emptyNote }

        let system = try loadPrompt("PromptSystem", bundle: bundle)
        let userTemplate = try loadPrompt("PromptUser", bundle: bundle)
        let user = userTemplate
            .replacingOccurrences(of: "{{referenceISO}}", with: ISO8601DateFormatter().string(from: referenceDate))
            .replacingOccurrences(of: "{{noteText}}", with: note)
        let body = MessageRequest(
            model: modelID,
            max_tokens: 1200,
            system: system,
            messages: [.init(role: "user", content: user)]
        )

        var request = URLRequest(url: LabAIConfig.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw HostedAIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw HostedAIError.httpStatus(http.statusCode)
        }

        do {
            let message = try JSONDecoder().decode(MessageResponse.self, from: data)
            let text = message.content
                .filter { $0.type == "text" }
                .compactMap(\.text)
                .joined(separator: "\n")
            let json = cleanedJSONText(text)
            let draft = try JSONDecoder().decode(NoteDraft.self, from: Data(json.utf8))
            return draft.result
        } catch {
            throw HostedAIError.invalidResponse
        }
    }

    private static func loadPrompt(_ name: String, bundle: Bundle) throws -> String {
        guard let url = bundle.url(forResource: name, withExtension: "md"),
              let content = try? String(contentsOf: url, encoding: .utf8),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw HostedAIError.missingPrompt(name)
        }
        return content
    }

    private static func cleanedJSONText(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("```") else { return trimmed }
        var lines = trimmed.components(separatedBy: .newlines)
        lines.removeFirst()
        if lines.last?.trimmingCharacters(in: .whitespacesAndNewlines) == "```" {
            lines.removeLast()
        }
        return lines.joined(separator: "\n")
    }

    private struct MessageRequest: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [Message]
    }

    private struct MessageResponse: Decodable {
        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }
        let content: [ContentBlock]
    }

    private struct NoteDraft: Decodable {
        struct Action: Decodable {
            let type: String
            let description: String
        }
        struct Balance: Decodable {
            let amount: Double?
            let currency: String?

            enum CodingKeys: String, CodingKey { case amount, currency }

            init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                currency = try values.decodeIfPresent(String.self, forKey: .currency)
                if let text = try? values.decode(String.self, forKey: .amount) {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        amount = nil
                    } else if let number = Double(trimmed), number.isFinite {
                        amount = number
                    } else {
                        throw HostedAIError.invalidResponse
                    }
                } else {
                    amount = try values.decodeIfPresent(Double.self, forKey: .amount)
                }
            }
        }
        let summary: String?
        let categories: [String]
        let balance_due: Balance?
        let actions: [Action]
        let appointment_timing: String?

        var result: ProcessedNoteResult {
            var seen = Set<String>()
            let categories = categories.compactMap(Self.nonEmpty)
                .filter { seen.insert($0.lowercased()).inserted }
            let followups = actions.prefix(8).compactMap { action -> ProposedFollowup? in
                guard let type = Self.nonEmpty(action.type),
                      let description = Self.nonEmpty(action.description) else { return nil }
                return ProposedFollowup(type: type, descriptionText: description)
            }
            let amount = balance_due?.amount.map { NSDecimalNumber(value: $0).decimalValue }
            return ProcessedNoteResult(
                summary: Self.nonEmpty(summary),
                balanceDueAmount: amount,
                balanceDueCurrency: amount == nil ? nil : Self.nonEmpty(balance_due?.currency)?.uppercased(),
                categories: categories,
                appointmentTiming: Self.nonEmpty(appointment_timing),
                followups: followups
            )
        }

        private nonisolated static func nonEmpty(_ value: String?) -> String? {
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }
    }
}

enum HostedAIError: LocalizedError {
    case missingKey
    case emptyNote
    case missingPrompt(String)
    case httpStatus(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "Add your training API key in LabAIConfig.swift, then rebuild the app."
        case .emptyNote:
            return "Enter a note before processing it."
        case .missingPrompt(let name):
            return "The app could not load \(name).md."
        case .httpStatus(401):
            return "The AI provider rejected the API key. Check your training key and rebuild."
        case .httpStatus(429):
            return "The AI provider is busy or the account has reached its limit. Try again later."
        case .httpStatus(let status):
            return "The AI provider request failed (HTTP \(status))."
        case .invalidResponse:
            return "The AI response could not be read. Your note has not been changed."
        }
    }
}
