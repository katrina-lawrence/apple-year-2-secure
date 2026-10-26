import Foundation

nonisolated struct AIActionDraft: Decodable {
    var type: String
    var description: String
}

nonisolated struct AIBalanceDueDraft: Decodable {
    var amount: Double?
    var currency: String?
}

nonisolated struct AIProcessedNoteDraft: Decodable {
    var summary: String
    var categories: [String]
    var balance_due: AIBalanceDueDraft?
    var actions: [AIActionDraft]
    var appointment_timing: String?
}

// The raw text is retained so an invalid JSON reply cannot hide a leaked lab GUID.
nonisolated struct HostedAIResponse {
    let text: String
    let model: String
    let requestID: String?
    let stopReason: String?

    func decodedDraft() throws -> AIProcessedNoteDraft {
        guard stopReason != "max_tokens" else { throw HostedAIError.truncatedOutput }
        var json = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if json.hasPrefix("```") {
            guard let firstNewline = json.firstIndex(of: "\n") else {
                throw HostedAIError.invalidDraft
            }
            let contentStart = json.index(after: firstNewline)
            guard let closingFence = json.range(of: "```", range: contentStart..<json.endIndex) else {
                throw HostedAIError.invalidDraft
            }
            json = String(json[contentStart..<closingFence.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        do {
            return try JSONDecoder().decode(AIProcessedNoteDraft.self, from: Data(json.utf8))
        } catch {
            throw HostedAIError.invalidDraft
        }
    }
}

nonisolated enum HostedAIClient {
    static func send(
        prompts: AIPromptTemplates,
        endpoint: String,
        modelID: String,
        apiKey: String?,
        session: URLSession = .shared
    ) async throws -> HostedAIResponse {
        let key = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !key.isEmpty, !key.lowercased().hasPrefix("replace"),
              UUID(uuidString: key) == nil else {
            throw HostedAIError.missingKey
        }
        let model = modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !model.isEmpty else { throw HostedAIError.missingModel }
        guard let url = URL(string: endpoint.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme == "https", url.host == "api.anthropic.com",
              url.path == "/v1/messages", url.user == nil, url.password == nil,
              url.query == nil, url.fragment == nil, url.port == nil || url.port == 443 else {
            throw HostedAIError.invalidEndpoint
        }

        let body = MessageRequest(
            model: model,
            max_tokens: 1500,
            system: prompts.system,
            messages: [.init(role: "user", content: prompts.user)]
        )
        var request = URLRequest(url: url)
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
        let message: MessageResponse
        do {
            message = try JSONDecoder().decode(MessageResponse.self, from: data)
        } catch {
            throw HostedAIError.invalidResponse
        }
        let text = message.content.filter { $0.type == "text" }
            .compactMap(\.text).joined(separator: "\n")
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw HostedAIError.emptyResponse
        }
        return HostedAIResponse(
            text: text,
            model: message.model,
            requestID: http.value(forHTTPHeaderField: "request-id"),
            stopReason: message.stop_reason
        )
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
        let model: String
        let content: [ContentBlock]
        let stop_reason: String?
    }
}

nonisolated enum HostedAIError: LocalizedError {
    case missingConfig
    case missingKey
    case missingModel
    case invalidEndpoint
    case httpStatus(Int)
    case invalidResponse
    case emptyResponse
    case invalidDraft
    case truncatedOutput

    var errorDescription: String? {
        switch self {
        case .missingConfig, .missingKey:
            return "Add your Anthropic API key to ThirdPartyAIConfig.plist, then rebuild. The supplied key is a placeholder."
        case .missingModel:
            return "Set a model in ThirdPartyAIConfig.plist, then rebuild."
        case .invalidEndpoint:
            return "Set the endpoint to https://api.anthropic.com/v1/messages in ThirdPartyAIConfig.plist."
        case .httpStatus(401):
            return "Anthropic rejected the API key. Check the local configuration and rebuild."
        case .httpStatus(402):
            return "Anthropic reported a billing problem. Check the API account."
        case .httpStatus(403):
            return "The API key does not have access to this request. Check the Anthropic account permissions."
        case .httpStatus(429):
            return "Anthropic reported a rate or usage limit. Try again later or check the account limits."
        case .httpStatus(let status):
            return "The Anthropic request failed (HTTP \(status)). Check the configured model and account."
        case .invalidResponse:
            return "The Anthropic response could not be read. The note has not been changed."
        case .emptyResponse:
            return "Anthropic returned no text. The note has not been changed."
        case .invalidDraft:
            return "The model reply did not match the expected note format. The note has not been changed. Use the prompt test runner to inspect the raw reply."
        case .truncatedOutput:
            return "The model reply reached the output limit. The note has not been changed."
        }
    }
}
