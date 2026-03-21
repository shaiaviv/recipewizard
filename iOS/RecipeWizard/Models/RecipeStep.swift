import SwiftData
import Foundation

@Model
final class RecipeStep {
    @Attribute(.unique) var id: UUID
    var stepNumber: Int
    var instruction: String
    var durationMinutes: Int?
    var recipe: Recipe?

    init(stepNumber: Int, instruction: String, durationMinutes: Int? = nil) {
        self.id = UUID()
        self.stepNumber = stepNumber
        self.instruction = instruction
        self.durationMinutes = durationMinutes
    }
}
