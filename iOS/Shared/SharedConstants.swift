import Foundation

enum SharedConstants {
    /// App Group identifier — must match entitlements in both targets
    static let appGroupID = "group.com.recipewizard.app"

    /// Backend URL — change to your Railway URL for production builds
    static let backendURL = "http://localhost:8000"

    /// Set to true once you have an Apple Developer account and CloudKit is configured
    static let cloudKitEnabled = false
    static let cloudKitContainerID = "iCloud.com.recipewizard.app"

    /// UserDefaults key for pending recipes written by the Share Extension
    static let pendingRecipesKey = "pendingRecipes"
}
