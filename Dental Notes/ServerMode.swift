import Foundation
import Security
import SwiftData
import SwiftUI
import Combine
import CryptoKit

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
    let spkiPins: [String]?

    enum CodingKeys: String, CodingKey {
        case baseURL
        case baseUrl
        case serverURL
        case serverUrl
        case endpoint
        case spkiPins
        case spki_pins
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseURL = container.decodeFirstNonEmptyString(for: [.baseURL, .baseUrl, .serverURL, .serverUrl, .endpoint])
        spkiPins = container.decodeFirstNonEmptyStringArray(for: [.spkiPins, .spki_pins])
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

    func decodeFirstNonEmptyStringArray(for keys: [Key]) -> [String]? {
        for key in keys {
            if let values = (try? decodeIfPresent([String].self, forKey: key)) ?? nil {
                let normalized = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                if !normalized.isEmpty {
                    return normalized
                }
            }
        }
        return nil
    }
}

fileprivate struct BackendServerConfiguration {
    let baseURL: URL
    let spkiPins: [String]
}

enum BackendConfigStore {
    private static let resourceName = "BackendConfig"
    private static let resourceExtension = "plist"

    fileprivate static func serverConfiguration() -> BackendServerConfiguration? {
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
              scheme == "https" else {
            return nil
        }
        guard let pins = file.spkiPins, pins.count >= 1 else {
            return nil
        }
        return BackendServerConfiguration(baseURL: parsed, spkiPins: pins)
    }
}

private enum TLSError: LocalizedError {
    case missingCAResource
    case invalidCACertificate
    case invalidSPKIPins

    var errorDescription: String? {
        switch self {
        case .missingCAResource:
            return "Missing bundled CA certificate (ca.crt)."
        case .invalidCACertificate:
            return "Bundled CA certificate (ca.crt) is invalid."
        case .invalidSPKIPins:
            return "Invalid SPKI pins in BackendConfig.plist."
        }
    }
}

private final class TLSPinningDelegate: NSObject, URLSessionDelegate {
    private let anchorCertificate: SecCertificate
    private let allowedPins: Set<String>

    init(spkiPins: [String]) throws {
        let normalizedPins = Set(spkiPins.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        guard normalizedPins.count >= 1 else {
            throw TLSError.invalidSPKIPins
        }
        guard normalizedPins.allSatisfy({ Data(base64Encoded: $0) != nil }) else {
            throw TLSError.invalidSPKIPins
        }

        self.allowedPins = normalizedPins
        self.anchorCertificate = try Self.loadAnchorCertificate()
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        do {
            guard try evaluate(trust: trust) else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
            completionHandler(.useCredential, URLCredential(trust: trust))
        } catch {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    private func evaluate(trust: SecTrust) throws -> Bool {
        let policy = SecPolicyCreateBasicX509()
        SecTrustSetPolicies(trust, policy)
        SecTrustSetAnchorCertificates(trust, [anchorCertificate] as CFArray)
        SecTrustSetAnchorCertificatesOnly(trust, true)

        guard SecTrustEvaluateWithError(trust, nil) else {
            return false
        }

        guard let certificateChain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let leafCertificate = certificateChain.first else {
            return false
        }
        let spkiHashBase64 = try Self.spkiSHA256Base64(from: leafCertificate)
        return allowedPins.contains(spkiHashBase64)
    }

    private static func loadAnchorCertificate() throws -> SecCertificate {
        guard let url = Bundle.main.url(forResource: "ca", withExtension: "crt") else {
            throw TLSError.missingCAResource
        }
        let rawData = try Data(contentsOf: url)
        let certificateData = try decodeCertificateData(from: rawData)
        guard let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) else {
            throw TLSError.invalidCACertificate
        }
        return certificate
    }

    private static func decodeCertificateData(from data: Data) throws -> Data {
        guard let text = String(data: data, encoding: .utf8),
              text.contains("BEGIN CERTIFICATE") else {
            return data
        }

        let beginMarker = "-----BEGIN CERTIFICATE-----"
        let endMarker = "-----END CERTIFICATE-----"
        guard let beginRange = text.range(of: beginMarker),
              let endRange = text.range(of: endMarker, range: beginRange.upperBound..<text.endIndex) else {
            throw TLSError.invalidCACertificate
        }

        let body = text[beginRange.upperBound..<endRange.lowerBound]
        let base64 = body.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        guard let decoded = Data(base64Encoded: base64) else {
            throw TLSError.invalidCACertificate
        }
        return decoded
    }

    private static func spkiSHA256Base64(from certificate: SecCertificate) throws -> String {
        guard let key = SecCertificateCopyKey(certificate) else {
            throw TLSError.invalidCACertificate
        }
        let spki = try subjectPublicKeyInfoData(from: key)
        let digest = SHA256.hash(data: spki)
        return Data(digest).base64EncodedString()
    }

    private static func subjectPublicKeyInfoData(from key: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let rawKeyData = SecKeyCopyExternalRepresentation(key, &error) as Data? else {
            throw (error?.takeRetainedValue() as Error?) ?? TLSError.invalidCACertificate
        }

        guard let attributes = SecKeyCopyAttributes(key) as? [CFString: Any],
              let keyType = attributes[kSecAttrKeyType] as? String else {
            throw TLSError.invalidCACertificate
        }
        let keySizeBits = (attributes[kSecAttrKeySizeInBits] as? NSNumber)?.intValue ?? 0

        let algorithmIdentifier: Data
        if keyType == (kSecAttrKeyTypeRSA as String) {
            algorithmIdentifier = derSequence(derOID([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01]) + derNull())
        } else if keyType == (kSecAttrKeyTypeECSECPrimeRandom as String) {
            let curveOID: [UInt8]
            switch keySizeBits {
            case 256:
                curveOID = [0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07]
            case 384:
                curveOID = [0x2B, 0x81, 0x04, 0x00, 0x22]
            case 521:
                curveOID = [0x2B, 0x81, 0x04, 0x00, 0x23]
            default:
                throw TLSError.invalidCACertificate
            }
            algorithmIdentifier = derSequence(
                derOID([0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01]) +
                derOID(curveOID)
            )
        } else {
            throw TLSError.invalidCACertificate
        }

        return derSequence(algorithmIdentifier + derBitString(rawKeyData))
    }

    private static func derSequence(_ payload: Data) -> Data {
        derTag(0x30, payload)
    }

    private static func derNull() -> Data {
        Data([0x05, 0x00])
    }

    private static func derOID(_ bytes: [UInt8]) -> Data {
        derTag(0x06, Data(bytes))
    }

    private static func derBitString(_ payload: Data) -> Data {
        var body = Data([0x00])
        body.append(payload)
        return derTag(0x03, body)
    }

    private static func derTag(_ tag: UInt8, _ payload: Data) -> Data {
        var data = Data([tag])
        data.append(derLength(payload.count))
        data.append(payload)
        return data
    }

    private static func derLength(_ length: Int) -> Data {
        if length < 0x80 {
            return Data([UInt8(length)])
        }
        var value = length
        var octets: [UInt8] = []
        while value > 0 {
            octets.insert(UInt8(value & 0xFF), at: 0)
            value >>= 8
        }
        var result = Data([0x80 | UInt8(octets.count)])
        result.append(contentsOf: octets)
        return result
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
    case invalidTLSConfiguration
    case unauthenticated
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .modeDisabled:
            return "Server mode is disabled for this build."
        case .invalidServerConfiguration:
            return "Invalid or missing server configuration. Ensure BackendConfig.plist has an https baseURL and at least one SPKI pin."
        case .invalidTLSConfiguration:
            return "TLS configuration failed. Ensure ca.crt is bundled and SPKI pins are valid."
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

private struct NoteProcessPayload: Encodable {
    let noteID: String
}

private struct ProcessNoteActionResponse: Decodable {
    let type: String?
    let description: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        self.type = container.decodeFlexibleString(forKeyNames: ["type"])
        self.description = container.decodeFlexibleString(forKeyNames: ["description", "descriptionText", "description_text"])
    }
}

private struct ProcessNoteBalanceDueResponse: Decodable {
    let amount: Double?
    let currency: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        self.amount = container.decodeFlexibleDouble(forKeyNames: ["amount"])
        self.currency = container.decodeFlexibleString(forKeyNames: ["currency"])
    }
}

private struct ProcessNoteResponse: Decodable {
    let summary: String?
    let categories: [String]
    let balanceDue: ProcessNoteBalanceDueResponse?
    let actions: [ProcessNoteActionResponse]
    let appointmentTiming: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        self.summary = container.decodeFlexibleString(forKeyNames: ["summary"])
        self.categories = container.decodeFlexibleStringArray(forKeyNames: ["categories"]) ?? []

        let balanceDueSnakeKey = AnyCodingKey("balance_due")
        let balanceDueCamelKey = AnyCodingKey("balanceDue")
        let decodedBalanceDueSnake: ProcessNoteBalanceDueResponse?
        do {
            decodedBalanceDueSnake = try container.decodeIfPresent(ProcessNoteBalanceDueResponse.self, forKey: balanceDueSnakeKey)
        } catch {
            decodedBalanceDueSnake = nil
        }
        let decodedBalanceDueCamel: ProcessNoteBalanceDueResponse?
        do {
            decodedBalanceDueCamel = try container.decodeIfPresent(ProcessNoteBalanceDueResponse.self, forKey: balanceDueCamelKey)
        } catch {
            decodedBalanceDueCamel = nil
        }
        self.balanceDue = decodedBalanceDueSnake ?? decodedBalanceDueCamel

        let actionsKey = AnyCodingKey("actions")
        let decodedActions: [ProcessNoteActionResponse]?
        do {
            decodedActions = try container.decodeIfPresent([ProcessNoteActionResponse].self, forKey: actionsKey)
        } catch {
            decodedActions = nil
        }
        self.actions = decodedActions ?? []
        self.appointmentTiming = container.decodeFlexibleString(forKeyNames: ["appointment_timing", "appointmentTiming"])
    }
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
    private var serverSession: URLSession?
    private var tlsDelegate: TLSPinningDelegate?

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

    func processNote(noteID: String) async throws -> ProcessedNoteResult {
        let payload = NoteProcessPayload(noteID: noteID)
        let response: ProcessNoteResponse = try await sendRequest(
            path: "/notes/process",
            method: "POST",
            body: payload,
            requiresAuthentication: true
        )

        let followups: [ProposedFollowup] = response.actions.prefix(8).compactMap { action in
            guard let rawType = action.type, let rawDescription = action.description else { return nil }
            let type = rawType.trimmingCharacters(in: .whitespacesAndNewlines)
            let description = rawDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !type.isEmpty, !description.isEmpty else { return nil }
            return ProposedFollowup(type: type, descriptionText: description)
        }

        let summary = trimmedOrNil(response.summary)

        let amount: Decimal?
        if let rawAmount = response.balanceDue?.amount {
            amount = NSDecimalNumber(value: rawAmount).decimalValue
        } else {
            amount = nil
        }

        let currency = amount == nil ? nil : normalizedCurrency(response.balanceDue?.currency)

        var seenCategories = Set<String>()
        let categories = response.categories
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seenCategories.insert($0.lowercased()).inserted }

        return ProcessedNoteResult(
            summary: summary,
            balanceDueAmount: amount,
            balanceDueCurrency: currency,
            categories: categories,
            appointmentTiming: trimmedOrNil(response.appointmentTiming),
            followups: followups
        )
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

        authError = nil
        let serverConfiguration = BackendConfigStore.serverConfiguration()
        backendBaseURL = serverConfiguration?.baseURL
        accessToken = AuthTokenKeychainStore.readAccessToken()
        refreshToken = AuthTokenKeychainStore.readRefreshToken()
        isAuthenticated = false
        serverSession = nil
        tlsDelegate = nil

        guard let serverConfiguration else {
            authError = "Add Dental Notes/BackendConfig.plist with an https baseURL and at least one SPKI pin."
            return
        }

        do {
            let delegate = try TLSPinningDelegate(spkiPins: serverConfiguration.spkiPins)
            let configuration = URLSessionConfiguration.ephemeral
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            configuration.urlCache = nil
            configuration.httpCookieStorage = nil
            configuration.httpShouldSetCookies = false

            tlsDelegate = delegate
            serverSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
            isAuthenticated = accessToken != nil && refreshToken != nil
        } catch {
            authError = message(for: error)
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
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
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
        guard let serverSession else { throw BackendError.invalidTLSConfiguration }

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

    private func trimmedOrNil(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func normalizedCurrency(_ value: String?) -> String? {
        guard let trimmed = trimmedOrNil(value) else { return nil }
        return trimmed.uppercased()
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
