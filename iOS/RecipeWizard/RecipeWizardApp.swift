import SwiftUI
import SwiftData

@main
struct RecipeWizardApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Recipe.self, Ingredient.self, RecipeStep.self])
        // CloudKit sync is disabled until you have a paid Apple Developer account.
        // When ready: change to ModelConfiguration(schema:, cloudKitDatabase: .private(SharedConstants.cloudKitContainerID))
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
