import SwiftUI

@Observable
final class ProfileViewModel {
    var stats: ProfileStats?
    var followers: [InstagramUser] = []
    var following: [InstagramUser] = []
    var mutuals: [InstagramUser] = []
    var nonMutuals: [InstagramUser] = []
    var isLoading: Bool = false
    var selectedTab: ProfileTab = .followers

    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func loadData() async {
        isLoading = true
        async let statsTask: () = loadStats()
        async let followersTask: () = loadFollowers()
        async let followingTask: () = loadFollowing()
        async let mutualsTask: () = loadMutuals()
        async let nonMutualsTask: () = loadNonMutuals()
        _ = await (statsTask, followersTask, followingTask, mutualsTask, nonMutualsTask)
        isLoading = false
    }

    private func loadStats() async {
        do {
            stats = try await apiService.fetchProfileStats()
        } catch {
            stats = ProfileStats(followers: 1243, following: 892, mutuals: 654, nonMutuals: 238, profileViews: 47)
        }
    }

    private func loadFollowers() async {
        do {
            followers = try await apiService.fetchFollowers()
        } catch {
            followers = sampleUsers
        }
    }

    private func loadFollowing() async {
        do {
            following = try await apiService.fetchFollowing()
        } catch {
            following = sampleUsers
        }
    }

    private func loadMutuals() async {
        do {
            mutuals = try await apiService.fetchMutuals()
        } catch {
            mutuals = []
        }
    }

    private func loadNonMutuals() async {
        do {
            nonMutuals = try await apiService.fetchNonMutuals()
        } catch {
            nonMutuals = []
        }
    }

    var sampleUsers: [InstagramUser] {
        (0..<12).map { i in
            InstagramUser(
                id: "sample_\(i)",
                username: ["emma.creates", "jake_photo", "sophia.fit", "alex.travel", "mia.art", "noah.dev", "olivia.style", "liam.music", "ava.cooks", "ethan.game", "luna.yoga", "mason.tech"][i],
                fullName: ["Emma Creates", "Jake Photo", "Sophia Fit", "Alex Travel", "Mia Art", "Noah Dev", "Olivia Style", "Liam Music", "Ava Cooks", "Ethan Game", "Luna Yoga", "Mason Tech"][i],
                profilePicURL: "https://i.pravatar.cc/150?img=\(i + 10)",
                bio: nil,
                followerCount: Int.random(in: 200...80000),
                followingCount: nil,
                isPrivate: false,
                isVerified: i < 3,
                followsBack: i % 2 == 0
            )
        }
    }
}

enum ProfileTab: String, CaseIterable {
    case followers = "Followers"
    case following = "Following"
    case mutuals = "Mutuals"
    case nonMutuals = "Non-Mutuals"

    var icon: String {
        switch self {
        case .followers: "person.2.fill"
        case .following: "person.badge.plus"
        case .mutuals: "arrow.left.arrow.right"
        case .nonMutuals: "person.fill.xmark"
        }
    }
}
