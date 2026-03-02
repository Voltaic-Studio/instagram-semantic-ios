import Foundation

@Observable
final class APIService {
    private let baseURL: String = "https://your-backend.com/api"
    private var authToken: String?

    var isAuthenticated: Bool { authToken != nil }

    func setToken(_ token: String) {
        authToken = token
        UserDefaults.standard.set(token, forKey: "auth_token")
    }

    func loadStoredToken() {
        authToken = UserDefaults.standard.string(forKey: "auth_token")
    }

    func clearToken() {
        authToken = nil
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }

    func login(username: String, password: String, twoFactorCode: String? = nil) async throws -> LoginResponse {
        var body: [String: String] = [
            "username": username,
            "password": password
        ]
        if let code = twoFactorCode {
            body["two_factor_code"] = code
        }
        return try await post("/login-instagram", body: body)
    }

    func fetchFollowers() async throws -> [InstagramUser] {
        try await get("/followers")
    }

    func fetchFollowing() async throws -> [InstagramUser] {
        try await get("/following")
    }

    func fetchMutuals() async throws -> [InstagramUser] {
        try await get("/mutuals")
    }

    func fetchNonMutuals() async throws -> [InstagramUser] {
        try await get("/non-mutuals")
    }

    func fetchProfileStats() async throws -> ProfileStats {
        try await get("/profile-stats")
    }

    func semanticSearch(query: String, scope: SearchScope) async throws -> [SearchResult] {
        try await get("/semantic-search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&scope=\(scope.rawValue)")
    }

    private func get<T: Codable & Sendable>(_ path: String) async throws -> T {
        var request = URLRequest(url: URL(string: baseURL + path)!)
        request.httpMethod = "GET"
        applyHeaders(&request)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post<T: Codable & Sendable>(_ path: String, body: [String: String]) async throws -> T {
        var request = URLRequest(url: URL(string: baseURL + path)!)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyHeaders(&request)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func applyHeaders(_ request: inout URLRequest) {
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }
}

nonisolated enum SearchScope: String, CaseIterable, Sendable {
    case followers
    case all

    var displayName: String {
        switch self {
        case .followers: "My Followers"
        case .all: "All Accounts"
        }
    }

    var icon: String {
        switch self {
        case .followers: "person.2"
        case .all: "globe"
        }
    }
}
