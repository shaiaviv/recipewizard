import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unsupportedURL
    case unauthorized
    case extractionFailed(String)
    case networkError(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .unsupportedURL: return "Only TikTok and Instagram URLs are supported"
        case .unauthorized: return "Please sign in to RecipeWizard first"
        case .extractionFailed(let msg): return "Extraction failed: \(msg)"
        case .networkError(let msg): return "Network error: \(msg)"
        case .decodingError(let msg): return "Failed to parse response: \(msg)"
        }
    }
}

actor RecipeAPIService {
    static let shared = RecipeAPIService()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 90
        config.timeoutIntervalForResource = 120
        return URLSession(configuration: config)
    }()

    func extractRecipe(from urlString: String) async throws -> RecipeResponse {
        guard let baseURL = URL(string: SharedConstants.backendURL) else {
            throw APIError.invalidURL
        }
        let endpoint = baseURL.appendingPathComponent("/api/v1/extract")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(to: &request)

        let body = ExtractRequest(url: urlString, includeThumbnail: true)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("No HTTP response")
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(RecipeResponse.self, from: data)
            } catch {
                throw APIError.decodingError(error.localizedDescription)
            }
        case 401:
            throw APIError.unauthorized
        case 422:
            throw APIError.unsupportedURL
        default:
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw APIError.extractionFailed(msg)
        }
    }

    func fetchUserRecipes() async throws -> [RecipeResponse] {
        guard let baseURL = URL(string: SharedConstants.backendURL) else {
            throw APIError.invalidURL
        }
        let endpoint = baseURL.appendingPathComponent("/api/v1/recipes")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        addAuthHeader(to: &request)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("No HTTP response")
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                return try JSONDecoder().decode([RecipeResponse].self, from: data)
            } catch {
                throw APIError.decodingError(error.localizedDescription)
            }
        case 401:
            throw APIError.unauthorized
        default:
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw APIError.extractionFailed(msg)
        }
    }

    func deleteRecipe(id: String) async throws {
        guard let baseURL = URL(string: SharedConstants.backendURL) else {
            throw APIError.invalidURL
        }
        let endpoint = baseURL.appendingPathComponent("/api/v1/recipes/\(id)")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "DELETE"
        addAuthHeader(to: &request)

        let (_, response): (Data, URLResponse)
        do {
            (_, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("No HTTP response")
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
    }

    // MARK: - Private

    private func addAuthHeader(to request: inout URLRequest) {
        let defaults = UserDefaults(suiteName: SharedConstants.appGroupID) ?? UserDefaults.standard
        if let token = defaults.string(forKey: SharedConstants.jwtTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}
