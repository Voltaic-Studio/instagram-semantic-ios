import SwiftUI

@Observable
final class SearchViewModel {
    var query: String = ""
    var results: [SearchResult] = []
    var isSearching: Bool = false
    var searchScope: SearchScope = .followers
    var errorMessage: String?
    var recentQueries: [String] = []

    private let apiService: APIService

    let suggestedQueries: [String] = [
        "Find me blonde girls",
        "People into fitness",
        "Photographers near me",
        "People I follow who don't follow back",
        "Friends who are into travel",
        "Music producers",
        "People with blue hair"
    ]

    init(apiService: APIService) {
        self.apiService = apiService
        loadRecentQueries()
    }

    func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        errorMessage = nil
        addRecentQuery(query)

        do {
            results = try await apiService.semanticSearch(query: query, scope: searchScope)
        } catch {
            errorMessage = "Search failed. Try again."
            results = sampleResults
        }
        isSearching = false
    }

    func clearResults() {
        results = []
        query = ""
    }

    private func addRecentQuery(_ q: String) {
        recentQueries.removeAll { $0 == q }
        recentQueries.insert(q, at: 0)
        if recentQueries.count > 10 {
            recentQueries = Array(recentQueries.prefix(10))
        }
        saveRecentQueries()
    }

    private func loadRecentQueries() {
        recentQueries = UserDefaults.standard.stringArray(forKey: "recent_queries") ?? []
    }

    private func saveRecentQueries() {
        UserDefaults.standard.set(recentQueries, forKey: "recent_queries")
    }

    var sampleResults: [SearchResult] {
        (0..<8).map { i in
            SearchResult(
                id: "\(i)",
                user: InstagramUser(
                    id: "\(i)",
                    username: "user_\(i)",
                    fullName: "Sample User \(i)",
                    profilePicURL: "https://i.pravatar.cc/150?img=\(i + 1)",
                    bio: "Just living my best life ✨",
                    followerCount: Int.random(in: 100...50000),
                    followingCount: Int.random(in: 50...2000),
                    isPrivate: false,
                    isVerified: i < 2,
                    followsBack: i % 2 == 0
                ),
                score: Double.random(in: 0.7...0.99),
                matchType: i % 2 == 0 ? "semantic" : "graph",
                tags: ["fitness", "travel", "photography"].shuffled().prefix(2).map { $0 }
            )
        }
    }
}
