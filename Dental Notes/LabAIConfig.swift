import Foundation

enum LabAIConfig {
    // Day 2 starter: this value is deliberately compiled into the app.
    // Replace it locally with a training key. Commit only the placeholder.
    nonisolated static let apiKey = "REPLACE_WITH_YOUR_TRAINING_KEY"
    nonisolated static let modelID = "claude-haiku-4-5-20251001"
    nonisolated static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
}
