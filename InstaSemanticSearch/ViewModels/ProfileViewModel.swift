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
    private var hasLoadedData: Bool = false

    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func loadData(force: Bool = false) async {
        if hasLoadedData && !force {
            return
        }
        isLoading = true
        async let statsTask: () = loadStats()
        async let followersTask: () = loadFollowers()
        async let followingTask: () = loadFollowing()
        async let mutualsTask: () = loadMutuals()
        async let nonMutualsTask: () = loadNonMutuals()
        _ = await (statsTask, followersTask, followingTask, mutualsTask, nonMutualsTask)
        hasLoadedData = true
        isLoading = false
    }

    private func loadStats() async {
        do {
            stats = try await apiService.fetchProfileStats()
        } catch {
            stats = nil
        }
    }

    private func loadFollowers() async {
        do {
            followers = try await apiService.fetchFollowers()
        } catch {
            followers = []
        }
    }

    private func loadFollowing() async {
        do {
            following = try await apiService.fetchFollowing()
        } catch {
            following = []
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
}

enum ProfileTab: String, CaseIterable {
    case followers = "Who Follows You"
    case following = "Who You Follow"
    case mutuals = "Follow You Back"
    case nonMutuals = "Don't Follow Back"

    var icon: String {
        switch self {
        case .followers: "person.2.fill"
        case .following: "person.badge.plus"
        case .mutuals: "arrow.triangle.2.circlepath.circle.fill"
        case .nonMutuals: "person.crop.circle.badge.xmark"
        }
    }
}
