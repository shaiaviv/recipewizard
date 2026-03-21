import SwiftData
import Foundation

@Model
final class Ingredient {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: String?
    var unit: String?
    var notes: String?
    var sortOrder: Int
    var recipe: Recipe?

    init(
        name: String,
        quantity: String? = nil,
        unit: String? = nil,
        notes: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.notes = notes
        self.sortOrder = sortOrder
    }

    var displayString: String {
        var parts: [String] = []
        if let qty = quantity { parts.append(qty) }
        if let u = unit { parts.append(u) }
        parts.append(name)
        if let n = notes { parts.append("(\(n))") }
        return parts.joined(separator: " ")
    }
}
