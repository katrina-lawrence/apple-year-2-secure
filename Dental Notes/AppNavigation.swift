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
        case .followup(let id):
            pendingFollowupID = id
            selectedTab = .followups
        }
    }

    func consumePendingFollowupRoute() {
        pendingFollowupID = nil
    }
}
