import Foundation

nonisolated struct InstagramUser: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let username: String
    let fullName: String
    let profilePicURL: String
    let bio: String?
    let followerCount: Int?
    let followingCount: Int?
    let isPrivate: Bool?
    let isVerified: Bool?
    let followsBack: Bool?

    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case profilePicURL = "profile_pic_url"
        case bio
        case followerCount = "follower_count"
        case followingCount = "following_count"
        case isPrivate = "is_private"
        case isVerified = "is_verified"
        case followsBack = "follows_back"
    }
}

nonisolated struct SearchResult: Codable, Sendable, Identifiable {
    let id: String
    let user: InstagramUser
    let score: Double?
    let matchType: String?
    let tags: [String]?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, user, score
        case matchType = "match_type"
        case tags
    }
}

nonisolated struct ProfileStats: Codable, Sendable {
    let followers: Int
    let following: Int
    let mutuals: Int
    let nonMutuals: Int
    let profileViews: Int?

    nonisolated enum CodingKeys: String, CodingKey {
        case followers, following, mutuals
        case nonMutuals = "non_mutuals"
        case profileViews = "profile_views"
    }
}

nonisolated struct LoginResponse: Codable, Sendable {
    let success: Bool
    let token: String?
    let user: InstagramUser?
    let requiresTwoFactor: Bool?
    let message: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case success, token, user
        case requiresTwoFactor = "requires_two_factor"
        case message
    }
}

nonisolated struct APIResponse<T: Codable & Sendable>: Codable, Sendable {
    let success: Bool
    let data: T?
    let message: String?
}

nonisolated struct SyncStatus: Codable, Sendable {
    let status: String
    let message: String?
    let progress: Int
    let error: String?

    var isActive: Bool {
        status == "queued" || status == "syncing"
    }
}

extension InstagramUser {
    var instagramAppURL: URL? {
        let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? username
        return URL(string: "instagram://user?username=\(encodedUsername)")
    }

    var instagramWebURL: URL? {
        URL(string: "https://www.instagram.com/\(username)/")
    }
}
