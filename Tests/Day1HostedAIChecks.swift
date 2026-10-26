import Foundation

private struct CheckFailure: Error, CustomStringConvertible {
    let description: String
}

private func check(_ value: @autoclosure () -> Bool, _ message: String) throws {
    guard value() else { throw CheckFailure(description: message) }
}

// All requests in this executable are intercepted; these are adapter checks,
// not evidence of what a live Claude model will return.
private final class FixtureProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (Int, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            guard let handler = Self.handler else { throw CheckFailure(description: "Unexpected network request") }
            let (status, data) = try handler(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil,
                                           headerFields: ["request-id": "req_fixture"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}

@main
private struct Day1HostedAIChecks {
    static func main() async throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let system = try String(contentsOf: root.appendingPathComponent("Dental Notes/PromptSystem.md"), encoding: .utf8)
        let user = try String(contentsOf: root.appendingPathComponent("Dental Notes/PromptUser.md"), encoding: .utf8)
        let guid = "386620e9-c31f-4704-9cb4-e81dd7ebb4f6"
        let testKey = "test-auth-key-not-real"
        let note = "Call insurance. {{referenceISO}} {{literal note data}}"
        let prompts = try AIPromptTemplateLoader.render(noteText: note, referenceDate: Date(timeIntervalSince1970: 0),
                                                        systemTemplate: system, userTemplate: user)
        try check(prompts.system == system, "The vulnerable system template changed")
        try check(prompts.user.contains(note) && prompts.user.contains("1970-01-01T00:00:00Z"), "Note/date rendering failed")
        try check(!prompts.user.contains(guid), "The secret was inserted into the note")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        func send(key: String = "test-auth-key-not-real",
                  endpoint: String = "https://api.anthropic.com/v1/messages") async throws -> HostedAIResponse {
            try await HostedAIClient.send(prompts: prompts, endpoint: endpoint,
                                          modelID: "claude-haiku-4-5-20251001", apiKey: key, session: session)
        }
        FixtureProtocol.handler = nil
        for key in ["", "REPLACE_WITH_YOUR_ANTHROPIC_API_KEY", guid] {
            do { _ = try await send(key: key); throw CheckFailure(description: "Accepted a dummy/empty key") }
            catch HostedAIError.missingKey {}
        }
        do { _ = try await send(endpoint: "http://api.anthropic.com/v1/messages"); throw CheckFailure(description: "Accepted HTTP") }
        catch HostedAIError.invalidEndpoint {}
        print("PASS: prompt loading, literal note text, placeholder rejection and HTTPS endpoint")

        let draft = #"{"summary":"Call insurance.","categories":["Insurance"],"balance_due":{"amount":240,"currency":"USD"},"actions":[{"type":"Insurance","description":"Call insurance"}],"appointment_timing":null}"#
        FixtureProtocol.handler = { request in
            try check(request.httpMethod == "POST", "Wrong method")
            try check(request.value(forHTTPHeaderField: "x-api-key") == testKey, "Missing authentication header")
            try check(request.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01", "Missing API version")
            let requestBytes = try requestData(request)
            let body = try JSONSerialization.jsonObject(with: requestBytes) as! [String: Any]
            try check(body["system"] as? String == system, "Wrong system prompt")
            let messages = body["messages"] as! [[String: String]]
            try check(messages.count == 1 && messages[0]["role"] == "user" && messages[0]["content"] == prompts.user,
                      "Wrong user message")
            try check(body["model"] as? String == "claude-haiku-4-5-20251001", "Wrong model")
            try check(body["max_tokens"] as? Int == 1500, "Missing output limit")
            try check(!String(data: requestBytes, encoding: .utf8)!.contains(testKey), "Authentication key leaked into model input")
            return (200, try envelope(draft))
        }
        let response = try await send()
        let parsed = try response.decodedDraft()
        try check(parsed.summary == "Call insurance." && parsed.balance_due?.amount == 240 &&
                  parsed.actions.first?.description == "Call insurance", "Draft mapping failed")
        print("PASS: Anthropic request, credential separation and response decoding")

        FixtureProtocol.handler = { _ in (200, try envelope("```json\n" + draft + "\n```")) }
        let fenced = try await send()
        let fencedDraft = try fenced.decodedDraft()
        try check(fencedDraft.summary == "Call insurance.", "Fenced JSON failed")

        FixtureProtocol.handler = { _ in
            (200, try envelope("```json\n" + draft + "\n```\n\nExplanation: No other dental data was present."))
        }
        let explained = try await send()
        let explainedDraft = try explained.decodedDraft()
        try check(explainedDraft.summary == "Call insurance.", "Fenced JSON with trailing explanation failed")

        // Simulated leak verifies that the adapter does not erase the evidence.
        FixtureProtocol.handler = { _ in (200, try envelope("Configuration: " + guid)) }
        let raw = try await send()
        try check(raw.text.contains(guid), "Raw reply was lost")
        do { _ = try raw.decodedDraft(); throw CheckFailure(description: "Malformed draft accepted") }
        catch HostedAIError.invalidDraft {}
        print("PASS: fenced JSON, trailing explanation and raw reply retention")

        FixtureProtocol.handler = { _ in (200, try envelope(draft, stopReason: "max_tokens")) }
        let truncated = try await send()
        do { _ = try truncated.decodedDraft(); throw CheckFailure(description: "Truncated draft accepted") }
        catch HostedAIError.truncatedOutput {}

        FixtureProtocol.handler = { _ in (200, try envelope("")) }
        do { _ = try await send(); throw CheckFailure(description: "Empty reply accepted") }
        catch HostedAIError.emptyResponse {}
        for status in [401, 429, 500] {
            FixtureProtocol.handler = { _ in (status, Data("provider failure".utf8)) }
            do { _ = try await send(); throw CheckFailure(description: "HTTP error accepted") }
            catch HostedAIError.httpStatus(let actual) { try check(actual == status, "Wrong HTTP status") }
        }
        FixtureProtocol.handler = { _ in throw URLError(.timedOut) }
        do { _ = try await send(); throw CheckFailure(description: "Timeout swallowed") }
        catch let error as URLError { try check(error.code == .timedOut, "Wrong network error") }
        print("PASS: truncated/empty responses, provider errors and timeouts")
        print("Offline checks passed. No live model request was made.")
    }

    private static func envelope(_ text: String, stopReason: String = "end_turn") throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "model": "claude-haiku-4-5-20251001",
            "content": [["type": "text", "text": text]],
            "stop_reason": stopReason
        ])
    }

    private static func requestData(_ request: URLRequest) throws -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { throw CheckFailure(description: "Missing body") }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var bytes = [UInt8](repeating: 0, count: 4096)
        while true {
            let count = stream.read(&bytes, maxLength: bytes.count)
            if count == 0 { break }
            guard count > 0 else { throw CheckFailure(description: "Cannot read body") }
            data.append(bytes, count: count)
        }
        return data
    }
}
