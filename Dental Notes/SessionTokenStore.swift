import Foundation

// Day 2 starter: the real login tokens are deliberately stored in preferences.
// Replace this storage during the security exercise.
struct SessionTokenStore {
    static let shared = SessionTokenStore()
    static let accessTokenKey = "day2.session.accessToken"
    static let refreshTokenKey = "day2.session.refreshToken"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func readAccessToken() -> String? {
        defaults.string(forKey: Self.accessTokenKey)
    }

    func readRefreshToken() -> String? {
        defaults.string(forKey: Self.refreshTokenKey)
    }

    func save(accessToken: String, refreshToken: String) {
        defaults.set(accessToken, forKey: Self.accessTokenKey)
        defaults.set(refreshToken, forKey: Self.refreshTokenKey)
    }

    func saveAccessToken(_ token: String) {
        defaults.set(token, forKey: Self.accessTokenKey)
    }

    func clearAll() {
        defaults.removeObject(forKey: Self.accessTokenKey)
        defaults.removeObject(forKey: Self.refreshTokenKey)
    }
}
