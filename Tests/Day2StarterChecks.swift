import Foundation

private struct CheckFailure: Error, CustomStringConvertible {
    let description: String
}

private func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw CheckFailure(description: message) }
}

// Every HTTP request is intercepted. No key or note leaves the test process.
private final class FixtureProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            guard let handler = Self.handler else {
                throw CheckFailure(description: "Unexpected HTTP request")
            }
            let (status, data) = try handler(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil,
                                           headerFields: ["Content-Type": "application/json"])!
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
private struct Day2StarterChecks {
    static func main() async throws {
        if CommandLine.arguments[1].hasPrefix("--") {
            try tokenCheck(mode: CommandLine.arguments[1], suite: CommandLine.arguments[2])
            return
        }
        guard let bundle = Bundle(path: CommandLine.arguments[1]) else {
            throw CheckFailure(description: "Missing prompt bundle")
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let referenceDate = Date(timeIntervalSince1970: 0)
        let testKey = "test-training-key-not-real"
        let note = "Call insurance about the crown. {{literal note text}}"
        let normalDraft = #"{"summary":"Call insurance.","categories":[" Insurance ","insurance"],"balance_due":{"amount":240,"currency":"usd"},"actions":[{"type":"Insurance","description":"Call insurance"}],"appointment_timing":null}"#

        func process(key: String = "test-training-key-not-real", text: String = "Call insurance.") async throws -> ProcessedNoteResult {
            try await HostedAIClient.processNote(from: text, referenceDate: referenceDate,
                                                 apiKey: key, session: session, bundle: bundle)
        }
        FixtureProtocol.handler = nil
        try await expectError("placeholder key is rejected before networking", matching: {
            if case .missingKey = $0 { return true }; return false
        }) { _ = try await process(key: "REPLACE_WITH_YOUR_TRAINING_KEY") }
        try await expectError("empty key is rejected before networking", matching: {
            if case .missingKey = $0 { return true }; return false
        }) { _ = try await process(key: "  ") }
        try await expectError("empty note is rejected before networking", matching: {
            if case .emptyNote = $0 { return true }; return false
        }) { _ = try await process(text: " \n ") }

        FixtureProtocol.handler = { request in
            try check(request.url?.absoluteString == "https://api.anthropic.com/v1/messages", "Wrong provider endpoint")
            try check(request.httpMethod == "POST", "Wrong request method")
            try check(request.value(forHTTPHeaderField: "x-api-key") == testKey, "Missing provider credential")
            try check(request.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01", "Missing API version")
            let body = try JSONSerialization.jsonObject(with: requestData(request)) as! [String: Any]
            try check(body["model"] as? String == LabAIConfig.modelID, "Wrong model")
            try check(body["max_tokens"] as? Int == 1200, "Missing output limit")
            let messages = body["messages"] as! [[String: String]]
            try check(messages.count == 1 && messages[0]["role"] == "user", "Wrong message structure")
            try check(messages[0]["content"]?.contains(note) == true, "Note was not included")
            try check(messages[0]["content"]?.contains("1970-01-01T00:00:00Z") == true, "Reference date was not rendered")
            try check((body["system"] as? String)?.contains("My Dental Companion") == true, "System prompt was not loaded")
            try check(!(body["system"] as! String).contains(testKey), "Key appeared in system prompt")
            return (200, try envelope(normalDraft))
        }
        let normal = try await process(text: note)
        try check(normal.summary == "Call insurance.", "Missing summary")
        try check(normal.balanceDueAmount == Decimal(240) && normal.balanceDueCurrency == "USD", "Balance mapping failed")
        try check(normal.categories == ["Insurance"], "Category mapping failed")
        try check(normal.followups.count == 1 && normal.followups[0].descriptionText == "Call insurance", "Follow-up mapping failed")
        print("PASS: direct provider request, prompts and result mapping")

        FixtureProtocol.handler = { _ in (200, try envelope("```json\n" + normalDraft + "\n```")) }
        let fenced = try await process()
        try check(fenced.summary == normal.summary, "Fenced JSON was not decoded")
        print("PASS: fenced JSON response")

        for balance in ["null", #"{"amount":null,"currency":null}"#, #"{"amount":"","currency":"USD"}"#] {
            let draft = "{\"summary\":null,\"categories\":[],\"balance_due\":\(balance),\"actions\":[],\"appointment_timing\":null}"
            FixtureProtocol.handler = { _ in (200, try envelope(draft)) }
            let result = try await process()
            try check(result.balanceDueAmount == nil && result.balanceDueCurrency == nil, "Missing balance became a value")
        }
        print("PASS: null and empty payment values")

        for invalid in ["not JSON", "{}", normalDraft.replacingOccurrences(of: "240", with: "\"not a number\"")] {
            FixtureProtocol.handler = { _ in (200, try envelope(invalid)) }
            try await expectError("malformed output is rejected", matching: {
                if case .invalidResponse = $0 { return true }; return false
            }) { _ = try await process() }
        }
        FixtureProtocol.handler = { _ in (200, Data(#"{"content":[]}"#.utf8)) }
        try await expectError("empty provider response is rejected", matching: {
            if case .invalidResponse = $0 { return true }; return false
        }) { _ = try await process() }

        for status in [401, 429, 500] {
            FixtureProtocol.handler = { _ in (status, Data()) }
            try await expectError("HTTP \(status) is reported as failure", matching: {
                if case .httpStatus(let actual) = $0 { return actual == status }; return false
            }) { _ = try await process() }
        }
        print("Day 2 starter checks passed.")
    }

    private static func tokenCheck(mode: String, suite: String) throws {
        let defaults = UserDefaults(suiteName: suite)!
        let store = SessionTokenStore(defaults: defaults)
        switch mode {
        case "--write-tokens":
            defaults.removePersistentDomain(forName: suite)
            store.save(accessToken: "test-access", refreshToken: "test-refresh")
            try check(defaults.string(forKey: SessionTokenStore.accessTokenKey) == "test-access", "Token was not stored in preferences")
            store.saveAccessToken("test-access-refreshed")
            try check(store.readRefreshToken() == "test-refresh", "Refreshing access erased refresh token")
            defaults.set("keep-this-setting", forKey: "unrelated")
            defaults.synchronize()
            print("PASS: token save and access-token refresh in UserDefaults")
        case "--read-tokens":
            try check(store.readAccessToken() == "test-access-refreshed", "Access token did not survive process restart")
            try check(store.readRefreshToken() == "test-refresh", "Refresh token did not survive process restart")
            print("PASS: both tokens reload in a new process")
        case "--clear-tokens":
            store.clearAll()
            defaults.synchronize()
        case "--verify-cleared":
            try check(store.readAccessToken() == nil && store.readRefreshToken() == nil, "Logout left session tokens")
            try check(defaults.string(forKey: "unrelated") == "keep-this-setting", "Logout removed unrelated settings")
            defaults.removePersistentDomain(forName: suite)
            defaults.synchronize()
            print("PASS: logout clears both tokens and preserves other preferences")
        default:
            throw CheckFailure(description: "Unknown check mode")
        }
    }

    private static func envelope(_ text: String) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["content": [["type": "text", "text": text]]])
    }

    private static func requestData(_ request: URLRequest) throws -> Data {
        if let data = request.httpBody { return data }
        guard let stream = request.httpBodyStream else { throw CheckFailure(description: "Missing request body") }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count == 0 { break }
            guard count > 0 else { throw CheckFailure(description: "Could not read request body") }
            data.append(contentsOf: buffer.prefix(count))
        }
        return data
    }

    private static func expectError(
        _ name: String,
        matching: (HostedAIError) -> Bool,
        operation: () async throws -> Void
    ) async throws {
        do {
            try await operation()
            throw CheckFailure(description: "Expected failure: \(name)")
        } catch let error as HostedAIError {
            try check(matching(error), "Unexpected error for \(name)")
            print("PASS: \(name)")
        }
    }
}
