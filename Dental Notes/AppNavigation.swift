import Foundation
import Combine

private enum AppDeepLinkConstants {
    static let scheme = "mydentalcompanion"
    static let followupsHost = "followups"
    static let followupHost = "followup"
}

enum AppDeepLinkRoute {
    case followups
    case followup(id: String)
}

enum AppIntentRouteStore {
    private static let appGroupInfoKey = "APP_GROUP_ID"
    private static let kindKey = "intent_route_kind"
    private static let followupIDKey = "intent_route_followup_id"
    private static let updatedAtKey = "intent_route_updated_at"

    private enum Kind: String {
        case followups
        case followup
    }

    private static var appGroupID: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: appGroupInfoKey) as? String else {
            assertionFailure("Missing APP_GROUP_ID in Info.plist")
            return nil
        }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            assertionFailure("APP_GROUP_ID is empty in Info.plist")
            return nil
        }
        return trimmedValue
    }

    private static var defaults: UserDefaults {
        guard let appGroupID else {
            return .standard
        }
        return UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func storeFollowupsRoute() {
        defaults.set(Kind.followups.rawValue, forKey: kindKey)
        defaults.removeObject(forKey: followupIDKey)
        defaults.set(Date().timeIntervalSince1970, forKey: updatedAtKey)
    }

    static func storeFollowupRoute(followupID: String) {
        let trimmedID = followupID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty else { return }
        defaults.set(Kind.followup.rawValue, forKey: kindKey)
        defaults.set(trimmedID, forKey: followupIDKey)
        defaults.set(Date().timeIntervalSince1970, forKey: updatedAtKey)
    }

    static func loadRoute() -> AppDeepLinkRoute? {
        guard let kindRawValue = defaults.string(forKey: kindKey),
              let kind = Kind(rawValue: kindRawValue) else {
            return nil
        }

        switch kind {
        case .followups:
            return .followups
        case .followup:
            guard let followupID = defaults.string(forKey: followupIDKey),
                  !followupID.isEmpty else {
                return nil
            }
            return .followup(id: followupID)
        }
    }

    static func clearRoute() {
        defaults.removeObject(forKey: kindKey)
        defaults.removeObject(forKey: followupIDKey)
        defaults.removeObject(forKey: updatedAtKey)
    }
}

enum AppDeepLinks {
    static func followupsURL() -> URL? {
        var components = URLComponents()
        components.scheme = AppDeepLinkConstants.scheme
        components.host = AppDeepLinkConstants.followupsHost
        return components.url
    }

    static func followupURL(id: String) -> URL? {
        let trimmedID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty else { return nil }

        var components = URLComponents()
        components.scheme = AppDeepLinkConstants.scheme
        components.host = AppDeepLinkConstants.followupHost
        components.path = "/\(trimmedID)"
        return components.url
    }

    static func route(from url: URL) -> AppDeepLinkRoute? {
        guard url.scheme?.lowercased() == AppDeepLinkConstants.scheme else {
            return nil
        }

        switch url.host?.lowercased() {
        case AppDeepLinkConstants.followupsHost:
            return .followups
        case AppDeepLinkConstants.followupHost:
            let followupID = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !followupID.isEmpty else { return nil }
            return .followup(id: followupID)
        default:
            return nil
        }
    }
}

enum AppTab: Hashable {
    case notes
    case followups
}

@MainActor
final class AppNavigationCoordinator: ObservableObject {
    @Published var selectedTab: AppTab = .notes
    @Published var pendingFollowupID: String?

    func open(route: AppDeepLinkRoute) {
        switch route {
        case .followups:
            pendingFollowupID = nil
            selectedTab = .followups
            AppIntentRouteStore.clearRoute()
        case .followup(let id):
            pendingFollowupID = id
            selectedTab = .followups
            AppIntentRouteStore.storeFollowupRoute(followupID: id)
        }
    }

    func restorePendingRouteIfNeeded() {
        guard let route = AppIntentRouteStore.loadRoute() else {
            return
        }

        switch route {
        case .followups:
            selectedTab = .followups
            AppIntentRouteStore.clearRoute()
        case .followup(let id):
            guard pendingFollowupID == nil else { return }
            pendingFollowupID = id
            selectedTab = .followups
        }
    }

    func consumePendingFollowupRoute() {
        pendingFollowupID = nil
        AppIntentRouteStore.clearRoute()
    }
}
