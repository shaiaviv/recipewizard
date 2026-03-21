import Foundation

enum SharedConstants {
    /// App Group identifier — must match entitlements in both targets
    static let appGroupID = "group.com.recipewizard.app"

    /// Backend URL — change to your Railway URL for production builds
    static let backendURL = "https://recipewizard-production-9be6.up.railway.app"

    /// Set to true once you have an Apple Developer account and CloudKit is configured
    static let cloudKitEnabled = false
    static let cloudKitContainerID = "iCloud.com.recipewizard.app"

    /// UserDefaults key for pending recipes written by the Share Extension
    static let pendingRecipesKey = "pendingRecipes"

    /// UserDefaults key for the JWT token (stored in App Group so Share Extension can read it)
    static let jwtTokenKey = "jwtToken"

    /// Google OAuth iOS client ID
    static let googleClientID = "313197419268-80pj3e1pq21imlofmpvkutrgaj9or1fj.apps.googleusercontent.com"
}
