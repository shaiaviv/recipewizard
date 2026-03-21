import Foundation

// MARK: - Codable models shared between main app and Share Extension
// These are NOT SwiftData models — they are plain Codable structs for JSON transport.

struct RecipeResponse: Codable {
    let id: String?
    let title: String
    let platform: String
    let sourceURL: String
    let thumbnailURL: String?
    let thumbnailBase64: String?
    let description: String?
    let cookTimeMinutes: Int?
    let prepTimeMinutes: Int?
    let servings: Int?
    let difficulty: String?
    let tags: [String]
    let ingredients: [IngredientResponse]
    let steps: [RecipeStepResponse]
    let extractionConfidence: Double
    let rawCaption: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case platform
        case sourceURL = "source_url"
        case thumbnailURL = "thumbnail_url"
        case thumbnailBase64 = "thumbnail_base64"
        case description
        case cookTimeMinutes = "cook_time_minutes"
        case prepTimeMinutes = "prep_time_minutes"
        case servings
        case difficulty
        case tags
        case ingredients
        case steps
        case extractionConfidence = "extraction_confidence"
        case rawCaption = "raw_caption"
    }
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

    enum CodingKeys: String, CodingKey {
        case stepNumber = "step_number"
        case instruction
        case durationMinutes = "duration_minutes"
    }
}

struct ExtractRequest: Codable {
    let url: String
    let includeThumbnail: Bool

    enum CodingKeys: String, CodingKey {
        case url
        case includeThumbnail = "include_thumbnail"
    }
}
