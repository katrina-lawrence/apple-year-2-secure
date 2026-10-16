import Foundation
import Security
import SwiftData
import SwiftUI
import Combine

enum AppRuntimeMode {
    case local
    case server

    static var current: AppRuntimeMode {
        #if SERVER_MODE
        .server
        #else
        .local
        #endif
    }

    var isServer: Bool {
        self == .server
    }
}

private struct BackendConfigFile: Decodable {
    let baseURL: String?

    enum CodingKeys: String, CodingKey {
        case baseURL
        case baseUrl
        case serverURL
        case serverUrl
        case endpoint
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseURL = container.decodeFirstNonEmptyString(for: [.baseURL, .baseUrl, .serverURL, .serverUrl, .endpoint])
    }
}

private extension KeyedDecodingContainer {
    func decodeFirstNonEmptyString(for keys: [Key]) -> String? {
        for key in keys {
            if let value = (try? decodeIfPresent(String.self, forKey: key)) ?? nil {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }
        return nil
    }
}

enum BackendConfigStore {
    private static let resourceName = "BackendConfig"
    private static let resourceExtension = "plist"

    static func serverBaseURL() -> URL? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension) else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        guard let file = try? PropertyListDecoder().decode(BackendConfigFile.self, from: data) else {
            return nil
        }
        guard let baseURLText = file.baseURL,
              let parsed = URL(string: baseURLText),
              let scheme = parsed.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }
        return parsed
    }
}

private enum AuthTokenKeychainStore {
    private static let service = "com.vincentdragnea.DentalNotes.backend"
    private static let accessAccount = "access_token"
    private static let refreshAccount = "refresh_token"

    static func readAccessToken() -> String? {
        read(account: accessAccount)
    }

    static func readRefreshToken() -> String? {
        read(account: refreshAccount)
    }

    static func save(accessToken: String, refreshToken: String) {
        save(value: accessToken, account: accessAccount)
        save(value: refreshToken, account: refreshAccount)
    }

    static func saveAccessToken(_ token: String) {
        save(value: token, account: accessAccount)
    }

    static func clearAll() {
        delete(account: accessAccount)
        delete(account: refreshAccount)
    }

    private static func save(value: String, account: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else {
            _ = delete(account: account)
            return
        }

        _ = delete(account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        _ = SecItemAdd(query as CFDictionary, nil)
    }

    @discardableResult
    private static func delete(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    private static func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        stringValue = "\(intValue)"
        self.intValue = intValue
    }

    init(_ value: String) {
        stringValue = value
        intValue = nil
    }
}

private extension KeyedDecodingContainer where Key == AnyCodingKey {
    func decodeFlexibleString(forKeyNames keyNames: [String]) -> String? {
        for keyName in keyNames {
            let key = AnyCodingKey(keyName)
            if let stringValue = (try? decodeIfPresent(String.self, forKey: key)) ?? nil {
                let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
            if let intValue = (try? decodeIfPresent(Int.self, forKey: key)) ?? nil {
                return String(intValue)
            }
            if let doubleValue = (try? decodeIfPresent(Double.self, forKey: key)) ?? nil {
                return String(doubleValue)
            }
        }
        return nil
    }

    func decodeFlexibleStringArray(forKeyNames keyNames: [String]) -> [String]? {
        for keyName in keyNames {
            let key = AnyCodingKey(keyName)
            if let values = (try? decodeIfPresent([String].self, forKey: key)) ?? nil {
                return values
            }
        }
        return nil
    }

    func decodeFlexibleDouble(forKeyNames keyNames: [String]) -> Double? {
        for keyName in keyNames {
            let key = AnyCodingKey(keyName)
            if let value = (try? decodeIfPresent(Double.self, forKey: key)) ?? nil {
                return value
            }
            if let value = (try? decodeIfPresent(Int.self, forKey: key)) ?? nil {
                return Double(value)
            }
            if let value = (try? decodeIfPresent(String.self, forKey: key)) ?? nil,
               let parsed = Double(value) {
                return parsed
            }
        }
        return nil
    }

    func decodeFlexibleBool(forKeyNames keyNames: [String]) -> Bool? {
        for keyName in keyNames {
            let key = AnyCodingKey(keyName)
            if let value = (try? decodeIfPresent(Bool.self, forKey: key)) ?? nil {
                return value
            }
            if let value = (try? decodeIfPresent(Int.self, forKey: key)) ?? nil {
                return value != 0
            }
            if let value = (try? decodeIfPresent(String.self, forKey: key)) ?? nil {
                switch value.lowercased() {
                case "1", "true", "yes": return true
                case "0", "false", "no": return false
                default: break
                }
            }
        }
        return nil
    }
}

private enum BackendError: LocalizedError {
    case modeDisabled
    case invalidServerConfiguration
    case unauthenticated
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .modeDisabled:
            return "Server mode is disabled for this build."
        case .invalidServerConfiguration:
            return "Invalid or missing server configuration."
        case .unauthenticated:
            return "Please log in to continue."
        case .invalidResponse:
            return "Invalid response from server."
        case .httpStatus(let status):
            return "Server request failed (\(status))."
        case .decodingFailed:
            return "Could not read server data."
        }
    }
}

private struct LoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        guard let accessToken = container.decodeFlexibleString(forKeyNames: ["access_token", "accessToken"]),
              let refreshToken = container.decodeFlexibleString(forKeyNames: ["refresh_token", "refreshToken"]) else {
            throw BackendError.decodingFailed
        }
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

private struct RefreshResponse: Decodable {
    let accessToken: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        guard let accessToken = container.decodeFlexibleString(forKeyNames: ["access_token", "accessToken"]) else {
            throw BackendError.decodingFailed
        }
        self.accessToken = accessToken
    }
}

private struct SyncUserResponse: Decodable {
    let notes: [ServerNote]
    let followups: [ServerFollowup]
}

private struct ServerNote: Decodable {
    let id: String
    let value: String
    let summary: String?
    let balanceDueAmount: Decimal?
    let balanceDueCurrency: String?
    let categories: [String]?
    let appointmentTiming: String?
    let createdAtUTC: Date?
    let editedAtUTC: Date?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        guard let id = container.decodeFlexibleString(forKeyNames: ["id", "note_id", "noteId"]),
              let value = container.decodeFlexibleString(forKeyNames: ["value"]) else {
            throw BackendError.decodingFailed
        }

        let createdString = container.decodeFlexibleString(forKeyNames: ["createdAtUTC", "created_at_utc", "createdAt"])
        let editedString = container.decodeFlexibleString(forKeyNames: ["editedAtUTC", "edited_at_utc", "editedAt"])

        self.id = id
        self.value = value
        self.summary = container.decodeFlexibleString(forKeyNames: ["summary"])
        if let amount = container.decodeFlexibleDouble(forKeyNames: ["balanceDueAmount", "balance_due_amount"]) {
            balanceDueAmount = Decimal(amount)
        } else {
            balanceDueAmount = nil
        }
        self.balanceDueCurrency = container.decodeFlexibleString(forKeyNames: ["balanceDueCurrency", "balance_due_currency"])
        self.categories = container.decodeFlexibleStringArray(forKeyNames: ["categories"])
        self.appointmentTiming = container.decodeFlexibleString(forKeyNames: ["appointmentTiming", "appointment_timing"])
        self.createdAtUTC = DateParsers.parseISO8601(createdString)
        self.editedAtUTC = DateParsers.parseISO8601(editedString)
    }
}

private struct ServerFollowup: Decodable {
    let id: String
    let descriptionText: String
    let type: String
    let noteID: String?
    let createdAtUTC: Date?
    let editedAtUTC: Date?
    let completed: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        guard let id = container.decodeFlexibleString(forKeyNames: ["id", "followup_id", "followupId"]),
              let descriptionText = container.decodeFlexibleString(forKeyNames: ["descriptionText", "description_text"]),
              let type = container.decodeFlexibleString(forKeyNames: ["type"]) else {
            throw BackendError.decodingFailed
        }

        let createdString = container.decodeFlexibleString(forKeyNames: ["createdAtUTC", "created_at_utc", "createdAt"])
        let editedString = container.decodeFlexibleString(forKeyNames: ["editedAtUTC", "edited_at_utc", "editedAt"])

        self.id = id
        self.descriptionText = descriptionText
        self.type = type
        self.noteID = container.decodeFlexibleString(forKeyNames: ["noteID", "note_id", "noteId"])
        self.createdAtUTC = DateParsers.parseISO8601(createdString)
        self.editedAtUTC = DateParsers.parseISO8601(editedString)
        self.completed = container.decodeFlexibleBool(forKeyNames: ["completed", "isCompleted", "is_completed"]) ?? false
    }
}

private enum DateParsers {
    private static let withFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let withoutFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let withoutTimezoneWithFractional: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return formatter
    }()

    private static let withoutTimezone: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    static func parseISO8601(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return withFractional.date(from: string)
            ?? withoutFractional.date(from: string)
            ?? withoutTimezoneWithFractional.date(from: string)
            ?? withoutTimezone.date(from: string)
    }
}

private struct LoginPayload: Encodable {
    let username: String
    let password: String
}

private struct RefreshPayload: Encodable {
    let refresh_token: String
}

private struct NoteCreatePayload: Encodable {
    let value: String
}

private struct NoteUpdatePayload: Encodable {
    let value: String
}

private struct FollowupCreatePayload: Encodable {
    let descriptionText: String
    let type: String
    let noteID: String?
}

private struct FollowupCreateResponse: Decodable {
    let id: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        guard let id = container.decodeFlexibleString(forKeyNames: ["id", "followup_id", "followupId"]) else {
            throw BackendError.decodingFailed
        }
        self.id = id
    }
}

private struct FollowupUpdatePayload: Encodable {
    let descriptionText: String?
    let type: String?
}

private struct FollowupCompletionPayload: Encodable {
    let completed: Bool
}

private struct SyncNoteFollowupPayload: Encodable {
    let descriptionText: String
    let type: String
}

private struct SyncNotePatchPayload: Encodable {
    let value: String
    let summary: String?
    let balanceDueAmount: Decimal?
    let balanceDueCurrency: String?
    let categories: [String]
    let appointmentTiming: String?
    let followups: [SyncNoteFollowupPayload]

    enum CodingKeys: String, CodingKey {
        case value
        case summary
        case balanceDueAmount
        case balanceDueCurrency
        case categories
        case appointmentTiming
        case followups
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)

        if let summary {
            try container.encode(summary, forKey: .summary)
        } else {
            try container.encodeNil(forKey: .summary)
        }

        if let balanceDueAmount {
            try container.encode(balanceDueAmount, forKey: .balanceDueAmount)
        } else {
            try container.encodeNil(forKey: .balanceDueAmount)
        }

        if let balanceDueCurrency {
            try container.encode(balanceDueCurrency, forKey: .balanceDueCurrency)
        } else {
            try container.encodeNil(forKey: .balanceDueCurrency)
        }

        try container.encode(categories, forKey: .categories)

        if let appointmentTiming {
            try container.encode(appointmentTiming, forKey: .appointmentTiming)
        } else {
            try container.encodeNil(forKey: .appointmentTiming)
        }

        try container.encode(followups, forKey: .followups)
    }
}

@MainActor
final class AppSessionViewModel: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isSyncing = false
    @Published private(set) var mode = AppRuntimeMode.current
    @Published private(set) var authError: String?
    @Published private(set) var syncError: String?

    private(set) var backendBaseURL: URL?
    private var accessToken: String?
    private var refreshToken: String?
    private var hasBootstrapped = false
    private let serverSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        return URLSession(configuration: configuration)
    }()

    init() {
        configureForMode()
    }

    func clearAuthError() {
        authError = nil
    }

    func clearSyncError() {
        syncError = nil
    }

    func bootstrapIfNeeded(modelContext: ModelContext) async {
        guard mode.isServer, !hasBootstrapped else { return }
        hasBootstrapped = true

        if isAuthenticated {
            _ = await refreshUserData(modelContext: modelContext)
        }
    }

    func login(username: String, password: String, modelContext: ModelContext) async -> Bool {
        guard mode.isServer else {
            authError = BackendError.modeDisabled.localizedDescription
            return false
        }
        authError = nil

        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty, !password.isEmpty else {
            authError = "Username and password are required."
            return false
        }

        do {
            let payload = LoginPayload(username: trimmedUsername, password: password)
            let loginResponse: LoginResponse = try await sendRequest(
                path: "/login",
                method: "POST",
                body: payload,
                requiresAuthentication: false
            )

            setTokens(accessToken: loginResponse.accessToken, refreshToken: loginResponse.refreshToken)
            let synced = await refreshUserData(modelContext: modelContext)
            if !synced {
                return false
            }
            return true
        } catch {
            authError = message(for: error)
            return false
        }
    }

    func register(username: String, password: String, modelContext: ModelContext) async -> Bool {
        guard mode.isServer else {
            authError = BackendError.modeDisabled.localizedDescription
            return false
        }
        authError = nil

        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty, !password.isEmpty else {
            authError = "Username and password are required."
            return false
        }

        do {
            let payload = LoginPayload(username: trimmedUsername, password: password)
            let _: EmptyResponse = try await sendRequest(
                path: "/register",
                method: "POST",
                body: payload,
                requiresAuthentication: false
            )
            return await login(username: trimmedUsername, password: password, modelContext: modelContext)
        } catch {
            authError = message(for: error)
            return false
        }
    }

    func logoutAndClearLocalData(modelContext: ModelContext) async {
        clearTokens()
        clearAllLocalData(modelContext: modelContext)
        syncError = nil
        authError = nil
    }

    func refreshUserData(modelContext: ModelContext) async -> Bool {
        guard mode.isServer else { return true }
        guard isAuthenticated else { return false }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let response: SyncUserResponse = try await sendRequest(
                path: "/sync/user",
                method: "GET",
                body: Optional<EmptyRequest>.none,
                requiresAuthentication: true
            )
            applySyncResponse(response, modelContext: modelContext)
            syncError = nil
            return true
        } catch {
            syncError = message(for: error)
            return false
        }
    }

    func createNote(value: String, modelContext: ModelContext) async -> Bool {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let payload = NoteCreatePayload(value: trimmedValue)
            let _: EmptyResponse = try await sendRequest(path: "/notes", method: "POST", body: payload, requiresAuthentication: true)
            return await refreshUserData(modelContext: modelContext)
        } catch {
            syncError = message(for: error)
            return false
        }
    }

    func updateNote(noteID: String, value: String, modelContext: ModelContext) async -> Bool {
        do {
            let payload = NoteUpdatePayload(value: value)
            let _: EmptyResponse = try await sendRequest(path: "/notes/\(noteID)", method: "PUT", body: payload, requiresAuthentication: true)
            return await refreshUserData(modelContext: modelContext)
        } catch {
            syncError = message(for: error)
            return false
        }
    }

    func deleteNote(noteID: String, modelContext: ModelContext) async -> Bool {
        do {
            let _: EmptyResponse = try await sendRequest(path: "/notes/\(noteID)", method: "DELETE", body: Optional<EmptyRequest>.none, requiresAuthentication: true)
            return await refreshUserData(modelContext: modelContext)
        } catch {
            syncError = message(for: error)
            return false
        }
    }

    func createFollowup(noteID: String?, type: String, descriptionText: String, modelContext: ModelContext) async -> Bool {
        guard let _ = await createFollowupAndReturnID(
            noteID: noteID,
            type: type,
            descriptionText: descriptionText,
            modelContext: modelContext
        ) else {
            return false
        }
        return true
    }

    func createFollowupAndReturnID(
        noteID: String?,
        type: String,
        descriptionText: String,
        modelContext: ModelContext
    ) async -> String? {
        do {
            let payload = FollowupCreatePayload(descriptionText: descriptionText, type: type, noteID: noteID)
            let response: FollowupCreateResponse = try await sendRequest(path: "/followups", method: "POST", body: payload, requiresAuthentication: true)
            let refreshed = await refreshUserData(modelContext: modelContext)
            guard refreshed else {
                return nil
            }
            return response.id
        } catch {
            syncError = message(for: error)
            return nil
        }
    }

    func deleteFollowup(followupID: String, modelContext: ModelContext) async -> Bool {
        do {
            let _: EmptyResponse = try await sendRequest(path: "/followups/\(followupID)", method: "DELETE", body: Optional<EmptyRequest>.none, requiresAuthentication: true)
            return await refreshUserData(modelContext: modelContext)
        } catch {
            syncError = message(for: error)
            return false
        }
    }

    func setFollowupCompletion(followupID: String, completed: Bool, modelContext: ModelContext) async -> Bool {
        do {
            let payload = FollowupCompletionPayload(completed: completed)
            let _: EmptyResponse = try await sendRequest(path: "/followups/\(followupID)/completion", method: "PATCH", body: payload, requiresAuthentication: true)
            return await refreshUserData(modelContext: modelContext)
        } catch {
            syncError = message(for: error)
            return false
        }
    }

    func saveProcessedNote(note: NoteEntity, result: ProcessedNoteResult, modelContext: ModelContext) async -> Bool {
        let followupPayloads = result.followups.map { item in
            SyncNoteFollowupPayload(descriptionText: item.descriptionText, type: item.type)
        }

        let payload = SyncNotePatchPayload(
            value: note.value,
            summary: result.summary,
            balanceDueAmount: result.balanceDueAmount,
            balanceDueCurrency: result.balanceDueCurrency,
            categories: result.categories,
            appointmentTiming: result.appointmentTiming,
            followups: followupPayloads
        )

        do {
            let _: EmptyResponse = try await sendRequest(path: "/sync/note/\(note.id)", method: "POST", body: payload, requiresAuthentication: true)
            return await refreshUserData(modelContext: modelContext)
        } catch {
            syncError = message(for: error)
            return false
        }
    }

    func updateFollowupText(
        followup: FollowupEntity,
        type: String,
        descriptionText: String,
        modelContext: ModelContext
    ) async -> Bool {
        do {
            let payload = FollowupUpdatePayload(descriptionText: descriptionText, type: type)
            let _: EmptyResponse = try await sendRequest(path: "/followups/\(followup.id)", method: "PATCH", body: payload, requiresAuthentication: true)
            return await refreshUserData(modelContext: modelContext)
        } catch {
            syncError = message(for: error)
            return false
        }
    }

    private func configureForMode() {
        mode = AppRuntimeMode.current
        guard mode.isServer else {
            isAuthenticated = true
            return
        }

        backendBaseURL = BackendConfigStore.serverBaseURL()
        accessToken = AuthTokenKeychainStore.readAccessToken()
        refreshToken = AuthTokenKeychainStore.readRefreshToken()
        isAuthenticated = backendBaseURL != nil && accessToken != nil && refreshToken != nil

        if backendBaseURL == nil {
            authError = "Add Dental Notes/BackendConfig.plist with a valid http:// or https:// base URL."
        }
    }

    private func setTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        isAuthenticated = true
        AuthTokenKeychainStore.save(accessToken: accessToken, refreshToken: refreshToken)
    }

    private func clearTokens() {
        accessToken = nil
        refreshToken = nil
        isAuthenticated = false
        AuthTokenKeychainStore.clearAll()
    }

    private func clearAllLocalData(modelContext: ModelContext) {
        let notes = (try? modelContext.fetch(FetchDescriptor<NoteEntity>())) ?? []
        for note in notes {
            modelContext.delete(note)
        }

        let followups = (try? modelContext.fetch(FetchDescriptor<FollowupEntity>())) ?? []
        for followup in followups {
            modelContext.delete(followup)
        }

        try? modelContext.save()
    }

    private func applySyncResponse(_ response: SyncUserResponse, modelContext: ModelContext) {
        let notes = (try? modelContext.fetch(FetchDescriptor<NoteEntity>())) ?? []
        let followups = (try? modelContext.fetch(FetchDescriptor<FollowupEntity>())) ?? []

        let notesByID = Dictionary(uniqueKeysWithValues: notes.map { ($0.id, $0) })
        let followupsByID = Dictionary(uniqueKeysWithValues: followups.map { ($0.id, $0) })

        var seenNoteIDs = Set<String>()
        var seenFollowupIDs = Set<String>()

        for remote in response.notes {
            seenNoteIDs.insert(remote.id)
            if let existing = notesByID[remote.id] {
                existing.value = remote.value
                existing.summary = remote.summary
                existing.balanceDueAmount = remote.balanceDueAmount
                existing.balanceDueCurrency = remote.balanceDueCurrency
                existing.categories = remote.categories
                existing.appointmentTiming = remote.appointmentTiming
                if let createdAtUTC = remote.createdAtUTC {
                    existing.createdAtUTC = createdAtUTC
                }
                if let editedAtUTC = remote.editedAtUTC {
                    existing.editedAtUTC = editedAtUTC
                }
            } else {
                let createdAtUTC = remote.createdAtUTC ?? Date()
                let editedAtUTC = remote.editedAtUTC ?? createdAtUTC
                let created = NoteEntity(
                    id: remote.id,
                    value: remote.value,
                    summary: remote.summary,
                    balanceDueAmount: remote.balanceDueAmount,
                    balanceDueCurrency: remote.balanceDueCurrency,
                    categories: remote.categories,
                    appointmentTiming: remote.appointmentTiming,
                    createdAtUTC: createdAtUTC,
                    editedAtUTC: editedAtUTC
                )
                modelContext.insert(created)
            }
        }

        for local in notes where !seenNoteIDs.contains(local.id) {
            modelContext.delete(local)
        }

        for remote in response.followups {
            seenFollowupIDs.insert(remote.id)
            if let existing = followupsByID[remote.id] {
                existing.descriptionText = remote.descriptionText
                existing.type = remote.type
                existing.noteID = remote.noteID
                if let createdAtUTC = remote.createdAtUTC {
                    existing.createdAtUTC = createdAtUTC
                }
                if let editedAtUTC = remote.editedAtUTC {
                    existing.editedAtUTC = editedAtUTC
                }
                existing.isCompleted = remote.completed
            } else {
                let createdAtUTC = remote.createdAtUTC ?? Date()
                let editedAtUTC = remote.editedAtUTC ?? createdAtUTC
                let created = FollowupEntity(
                    id: remote.id,
                    descriptionText: remote.descriptionText,
                    type: remote.type,
                    noteID: remote.noteID,
                    createdAtUTC: createdAtUTC,
                    editedAtUTC: editedAtUTC,
                    isCompleted: remote.completed
                )
                modelContext.insert(created)
            }
        }

        for local in followups where !seenFollowupIDs.contains(local.id) {
            modelContext.delete(local)
        }

        try? modelContext.save()
    }

    private func message(for error: Error) -> String {
        if let backendError = error as? BackendError {
            return backendError.localizedDescription
        }
        if let urlError = error as? URLError {
            return urlError.localizedDescription
        }
        return "Request failed. Please try again."
    }

    private func sendRequest<Response: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        requiresAuthentication: Bool
    ) async throws -> Response {
        let data = try await sendRawRequest(path: path, method: method, body: body, requiresAuthentication: requiresAuthentication)

        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }

        do {
            return try jsonDecoder.decode(Response.self, from: data)
        } catch {
            throw BackendError.decodingFailed
        }
    }

    private func sendRawRequest<Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        requiresAuthentication: Bool,
        hasRetriedAfterRefresh: Bool = false
    ) async throws -> Data {
        guard mode.isServer else { throw BackendError.modeDisabled }
        guard let baseURL = backendBaseURL else { throw BackendError.invalidServerConfiguration }

        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appending(path: normalizedPath)

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        if requiresAuthentication {
            guard let accessToken else {
                throw BackendError.unauthenticated
            }
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await serverSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        if httpResponse.statusCode == 401,
           requiresAuthentication,
           !hasRetriedAfterRefresh,
           try await refreshAccessToken() {
            return try await sendRawRequest(
                path: path,
                method: method,
                body: body,
                requiresAuthentication: requiresAuthentication,
                hasRetriedAfterRefresh: true
            )
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                clearTokens()
                throw BackendError.unauthenticated
            }
            throw BackendError.httpStatus(httpResponse.statusCode)
        }

        return data
    }

    private func refreshAccessToken() async throws -> Bool {
        guard let refreshToken else {
            clearTokens()
            return false
        }

        do {
            let payload = RefreshPayload(refresh_token: refreshToken)
            let response: RefreshResponse = try await sendRequest(
                path: "/refresh",
                method: "POST",
                body: payload,
                requiresAuthentication: false
            )
            accessToken = response.accessToken
            AuthTokenKeychainStore.saveAccessToken(response.accessToken)
            isAuthenticated = true
            return true
        } catch {
            clearTokens()
            return false
        }
    }

    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = DateParsers.parseISO8601(string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
        return decoder
    }
}

private struct EmptyRequest: Encodable {}
private struct EmptyResponse: Decodable {}

struct ServerAuthenticationView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var session: AppSessionViewModel

    @State private var isRegisterMode = false
    @State private var username = ""
    @State private var password = ""
    @State private var isSubmitting = false

    private var submitDisabled: Bool {
        isSubmitting || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Server Login") {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)

                    if let baseURL = session.backendBaseURL {
                        Text("Server: \(baseURL.absoluteString)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Missing Dental Notes/BackendConfig.plist")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if let authError = session.authError {
                        Text(authError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        submit()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text(isRegisterMode ? "Create Account" : "Log In")
                        }
                    }
                    .disabled(submitDisabled || session.backendBaseURL == nil)
                }

                Section {
                    Button(isRegisterMode ? "Use Existing Account" : "Create New Account") {
                        isRegisterMode.toggle()
                        session.clearAuthError()
                    }
                }
            }
            .navigationTitle("Authentication")
            .onChange(of: username) { _, _ in
                session.clearAuthError()
            }
            .onChange(of: password) { _, _ in
                session.clearAuthError()
            }
        }
    }

    private func submit() {
        guard !isSubmitting else { return }

        isSubmitting = true
        Task { @MainActor in
            let success: Bool
            if isRegisterMode {
                success = await session.register(username: username, password: password, modelContext: modelContext)
            } else {
                success = await session.login(username: username, password: password, modelContext: modelContext)
            }

            await MainActor.run {
                if success {
                    password = ""
                }
                isSubmitting = false
            }
        }
    }
}
