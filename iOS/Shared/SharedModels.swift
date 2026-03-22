import Foundation

// MARK: - Codable models shared between main app and Share Extension
// These are NOT SwiftData models — they are plain Codable structs for JSON transport.

struct RecipeResponse: Codable {
    let id: String?
    let title: String
    let platform: String
    let sourceUrl: String
    let thumbnailUrl: String?
    let thumbnailBase64: String?
    let description: String?
    let cookTimeMinutes: Int?
    let prepTimeMinutes: Int?
    let servings: Int?
    let difficulty: String?
    let tags: [String]?
    let ingredients: [IngredientResponse]
    let steps: [RecipeStepResponse]
    let extractionConfidence: Double?
    let rawCaption: String?
}

struct IngredientResponse: Codable {
    let name: String
    let quantity: String?
    let unit: String?
    let notes: String?
}

struct RecipeStepResponse: Codable {
    let stepNumber: Int
    let instruction: String
    let durationMinutes: Int?
}

struct ExtractRequest: Codable {
    let url: String
    let includeThumbnail: Bool

    enum CodingKeys: String, CodingKey {
        case url
        case includeThumbnail = "include_thumbnail"
    }
}
