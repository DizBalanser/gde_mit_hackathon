import Foundation

enum APIConfig {
    // MARK: - Azure OpenAI
    static let azureEndpoint = "https://besh.cognitiveservices.azure.com"
    static let azureAPIKey = "YOUR_AZURE_API_KEY_HERE"
    static let azureAPIKeySecondary = "YOUR_AZURE_API_KEY_SECONDARY_HERE"
    static let azureAPIVersion = "2024-12-01-preview"

    static let chatDeployment = "gpt-4o"

    // MARK: - Computed Azure URLs
    static var chatCompletionsURL: String {
        "\(azureEndpoint)/openai/deployments/\(chatDeployment)/chat/completions?api-version=\(azureAPIVersion)"
    }

    // MARK: - Medical Database APIs (free, no keys required)
    static let openFDABaseURL = "https://api.fda.gov"
    static let medlinePlusSearchURL = "https://wsearch.nlm.nih.gov/ws/query"
}
