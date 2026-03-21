import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unsupportedURL
    case extractionFailed(String)
    case networkError(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .unsupportedURL: return "Only TikTok and Instagram URLs are supported"
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
                return try JSONDecoder().decode(RecipeResponse.self, from: data)
            } catch {
                throw APIError.decodingError(error.localizedDescription)
            }
        case 422:
            throw APIError.unsupportedURL
        default:
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw APIError.extractionFailed(msg)
        }
    }
}
