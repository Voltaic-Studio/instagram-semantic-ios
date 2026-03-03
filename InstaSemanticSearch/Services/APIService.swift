import Foundation

@Observable
final class APIService {
    private let baseURL: String = Config.backendBaseURL
    private var authToken: String?

    var isAuthenticated: Bool { authToken != nil }
    var instagramLoginURL: URL? { URL(string: baseURL + "/auth/instagram/login") }

    func setToken(_ token: String) {
        authToken = token
        KeychainService.saveToken(token)
    }

    func loadStoredToken() {
        authToken = KeychainService.loadToken()
    }

    func clearToken() {
        authToken = nil
        KeychainService.deleteToken()
    }

    func login(username: String, password: String, twoFactorCode: String? = nil) async throws -> LoginResponse {
        print("[APIService] login() baseURL=\(baseURL)")
        var body: [String: String] = [
            "username": username,
            "password": password
        ]
        if let code = twoFactorCode {
            body["two_factor_code"] = code
        }
        return try await post("/api/auth/instagram/login", body: body)
    }

    func fetchCurrentUser() async throws -> InstagramUser {
        try await get("/api/auth/me")
    }

    func fetchSyncStatus() async throws -> SyncStatus {
        try await get("/api/auth/sync-status")
    }

    func refreshGraph() async throws {
        let _: EmptyResponse = try await post("/api/auth/refresh", body: [:])
    }

    func fetchFollowers() async throws -> [InstagramUser] {
        try await get("/api/followers")
    }

    func fetchFollowing() async throws -> [InstagramUser] {
        try await get("/api/following")
    }

    func fetchMutuals() async throws -> [InstagramUser] {
        try await get("/api/mutuals")
    }

    func fetchNonMutuals() async throws -> [InstagramUser] {
        try await get("/api/non-mutuals")
    }

    func fetchProfileStats() async throws -> ProfileStats {
        try await get("/api/profile-stats")
    }

    func semanticSearch(query: String, scope: SearchScope) async throws -> [SearchResult] {
        try await get("/api/semantic-search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&scope=\(scope.rawValue)")
    }

    private func get<T: Codable & Sendable>(_ path: String) async throws -> T {
        let url = URL(string: baseURL + path)!
        print("[APIService] GET \(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(&request)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post<T: Codable & Sendable>(_ path: String, body: [String: String]) async throws -> T {
        let url = URL(string: baseURL + path)!
        print("[APIService] POST \(url.absoluteString)")
        print("[APIService] POST body keys=\(Array(body.keys).sorted())")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyHeaders(&request)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            print("[APIService] Response status=\(httpResponse.statusCode) url=\(url.absoluteString)")
        }
        try validate(response: response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func applyHeaders(_ request: inout URLRequest) {
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if request.url?.host?.contains("ngrok-free.app") == true {
            request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[APIService] Invalid non-HTTP response")
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let rawMessage = String(data: data, encoding: .utf8) ?? "Request failed"
            let message = sanitizeServerMessage(rawMessage)
            print("[APIService] Server error status=\(httpResponse.statusCode) body=\(message)")
            throw APIError.server(message)
        }
    }

    private func sanitizeServerMessage(_ message: String) -> String {
        if message.lowercased().contains("<html") || message.lowercased().contains("<!doctype html") {
            return "Server returned an HTML error page."
        }
        let trimmed = message.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 280 {
            return String(trimmed.prefix(280)) + "..."
        }
        return trimmed
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case server(String)

    var isUnauthorized: Bool {
        switch self {
        case .server(let message):
            return message.contains("\"detail\":\"Missing bearer token\"")
                || message.contains("\"detail\":\"Invalid token\"")
                || message.contains("\"detail\":\"Account not found\"")
        case .invalidResponse:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case .server(let message):
            return message
        }
    }
}

nonisolated struct EmptyResponse: Codable, Sendable {}

nonisolated enum SearchScope: String, CaseIterable, Sendable {
    case following
    case followers

    var displayName: String {
        switch self {
        case .following: "Who You Follow"
        case .followers: "Who Follows You"
        }
    }

    var icon: String {
        switch self {
        case .following: "person.badge.plus"
        case .followers: "person.2"
        }
    }
}
