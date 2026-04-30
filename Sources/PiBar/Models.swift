import Foundation

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

struct AvailableModels: Codable {
    let providers: [String: Provider]
}

struct Provider: Codable {
    let models: [ModelInfo]
}

struct ModelInfo: Codable, Identifiable {
    let id: String
    let name: String
}
