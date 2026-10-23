import Foundation

enum Day5SupportUploadConfiguration {
    // Synthetic training value; it is not connected to an account or service.
    static let apiToken = "ghp_7Rr9mH2vK4xQ8cN6sT1yW5pL3dF0gJ2bZ9uA"

    static var authorizationHeader: String {
        "Bearer \(apiToken)"
    }
}
