import Foundation
import GoogleSignIn

@Observable
final class AuthService {
    static let shared = AuthService()

    private(set) var isAuthenticated = false
    private(set) var currentUser: UserInfo?

    struct UserInfo {
        let id: String
        let email: String
        let name: String
        let avatarUrl: String?
    }

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: SharedConstants.appGroupID)
    }

    private init() {
        isAuthenticated = defaults?.string(forKey: SharedConstants.jwtTokenKey) != nil
    }

    var jwtToken: String? {
        defaults?.string(forKey: SharedConstants.jwtTokenKey)
    }

    // MARK: - Configuration (call from RecipeWizardApp.init)

    func configure() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: SharedConstants.googleClientID
        )
        // Restore previous sign-in silently
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, _ in
            guard let self, let user else { return }
            Task { try? await self.handleGoogleUser(user) }
        }
    }

    // MARK: - Sign In / Out

    @MainActor
    func signIn(presenting viewController: UIViewController) async throws {
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        try await handleGoogleUser(result.user)
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        defaults?.removeObject(forKey: SharedConstants.jwtTokenKey)
        isAuthenticated = false
        currentUser = nil
    }

    // MARK: - Private

    private func handleGoogleUser(_ user: GIDGoogleUser) async throws {
        guard let idToken = user.idToken?.tokenString else {
            throw URLError(.userAuthenticationRequired)
        }
        try await exchangeGoogleToken(idToken)
    }

    private func exchangeGoogleToken(_ idToken: String) async throws {
        guard let url = URL(string: "\(SharedConstants.backendURL)/api/v1/auth/google") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["idToken": idToken])

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)

        defaults?.set(response.token, forKey: SharedConstants.jwtTokenKey)
        currentUser = UserInfo(
            id: response.user.id,
            email: response.user.email,
            name: response.user.name,
            avatarUrl: response.user.avatarUrl
        )
        isAuthenticated = true
    }
}

// MARK: - Private response types

private struct AuthResponse: Decodable {
    let token: String
    let user: AuthUserInfo

    struct AuthUserInfo: Decodable {
        let id: String
        let email: String
        let name: String
        let avatarUrl: String?

        enum CodingKeys: String, CodingKey {
            case id, email, name, avatarUrl
        }
    }
}
