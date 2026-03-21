import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct RecipeWizardApp: App {
    let container: ModelContainer
    private let auth = AuthService.shared

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
        auth.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isAuthenticated {
                    ContentView()
                        .modelContainer(container)
                } else {
                    LoginView()
                }
            }
            .environment(auth)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
