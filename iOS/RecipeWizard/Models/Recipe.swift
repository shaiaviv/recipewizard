import SwiftData
import Foundation

@Model
final class Recipe {
    @Attribute(.unique) var id: UUID
    var title: String
    var sourceURL: String
    var platform: String
    var thumbnailData: Data?
    var recipeDescription: String?
    var cookTimeMinutes: Int?
    var prepTimeMinutes: Int?
    var servings: Int?
    var difficulty: String?
    // CloudKit doesn't support native [String] arrays in SwiftData — encode as JSON
    var tagsData: Data
    var extractionConfidence: Double
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade) var ingredients: [Ingredient]
    @Relationship(deleteRule: .cascade) var steps: [RecipeStep]

    var tags: [String] {
        get { (try? JSONDecoder().decode([String].self, from: tagsData)) ?? [] }
        set { tagsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    init(
        id: UUID = UUID(),
        title: String,
        sourceURL: String,
        platform: String
    ) {
        self.id = id
        self.title = title
        self.sourceURL = sourceURL
        self.platform = platform
        self.tagsData = Data()
        self.extractionConfidence = 0
        self.createdAt = Date()
        self.updatedAt = Date()
        self.ingredients = []
        self.steps = []
    }

    /// Populate from an API response
    convenience init(from response: RecipeResponse) {
        self.init(
            title: response.title,
            sourceURL: response.sourceURL,
            platform: response.platform
        )
        self.recipeDescription = response.description
        self.cookTimeMinutes = response.cookTimeMinutes
        self.prepTimeMinutes = response.prepTimeMinutes
        self.servings = response.servings
        self.difficulty = response.difficulty
        self.tags = response.tags
        self.extractionConfidence = response.extractionConfidence

        if let b64 = response.thumbnailBase64,
           let data = Data(base64Encoded: b64.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")) {
            self.thumbnailData = data
        }

        self.ingredients = response.ingredients.enumerated().map { i, ing in
            Ingredient(name: ing.name, quantity: ing.quantity, unit: ing.unit, notes: ing.notes, sortOrder: i)
        }

        self.steps = response.steps.map { step in
            RecipeStep(stepNumber: step.stepNumber, instruction: step.instruction, durationMinutes: step.durationMinutes)
        }
    }

    var totalTimeMinutes: Int? {
        let cook = cookTimeMinutes ?? 0
        let prep = prepTimeMinutes ?? 0
        let total = cook + prep
        return total > 0 ? total : nil
    }

    var needsReview: Bool {
        extractionConfidence < 0.5
    }
}
