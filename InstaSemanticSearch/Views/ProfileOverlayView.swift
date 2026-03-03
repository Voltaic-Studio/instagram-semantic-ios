import SwiftUI

struct ProfileOverlayView: View {
    @Bindable var viewModel: ProfileViewModel
    @Bindable var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var appeared: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader

                    statsGrid

                    tabSelector

                    userList

                    logoutButton

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
        .presentationContentInteraction(.scrolls)
    }

    private var profileHeader: some View {
        HStack(spacing: 16) {
            Color(.tertiarySystemBackground)
                .frame(width: 72, height: 72)
                .overlay {
                    if let user = appViewModel.currentUser {
                        AsyncImage(url: URL(string: user.profilePicURL)) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .allowsHitTesting(false)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundStyle(.tertiary)
                    }
                }
                .clipShape(Circle())
                .overlay(Circle().stroke(.primary.opacity(0.08), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text(appViewModel.currentUser?.fullName ?? "Your Profile")
                    .font(.title3.bold())

                Text("@\(appViewModel.currentUser?.username ?? "username")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let views = viewModel.stats?.profileViews {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                        Text("\(views) profile views today")
                            .font(.caption)
                    }
                    .foregroundStyle(.purple)
                }
            }

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
    }

    private var statsGrid: some View {
        let stats = viewModel.stats
        let items: [(String, String, String)] = [
            ("\(stats?.followers ?? 0)", "Followers", "person.2.fill"),
            ("\(stats?.following ?? 0)", "Following", "person.badge.plus"),
            ("\(stats?.mutuals ?? 0)", "Follow you back", "arrow.triangle.2.circlepath.circle.fill"),
            ("\(stats?.nonMutuals ?? 0)", "Don't follow back", "person.crop.circle.badge.xmark")
        ]

        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 8) {
                    Image(systemName: item.2)
                        .font(.title3)
                        .foregroundStyle(.purple.opacity(0.6))

                    Text(item.0)
                        .font(.system(.title2, design: .rounded, weight: .bold))

                    Text(item.1)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.secondarySystemBackground))
                .clipShape(.rect(cornerRadius: 14))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.spring(response: 0.4).delay(Double(index) * 0.06), value: appeared)
            }
        }
    }

    private var tabSelector: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(ProfileTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.snappy) {
                            viewModel.selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.rawValue)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            viewModel.selectedTab == tab
                                ? Color.primary.opacity(0.1)
                                : Color(.tertiarySystemBackground)
                        )
                        .foregroundStyle(viewModel.selectedTab == tab ? .primary : .secondary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
    }

    private var userList: some View {
        let users: [InstagramUser] = {
            switch viewModel.selectedTab {
            case .followers: viewModel.followers
            case .following: viewModel.following
            case .mutuals: viewModel.mutuals
            case .nonMutuals: viewModel.nonMutuals
            }
        }()

        return VStack(spacing: 0) {
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if users.isEmpty {
                ContentUnavailableView(
                    "No users yet",
                    systemImage: "person.slash",
                    description: Text("Connect your backend to see real data.")
                )
                .padding(.vertical, 20)
            } else {
                ForEach(users) { user in
                    UserRow(user: user)
                    if user.id != users.last?.id {
                        Divider().padding(.leading, 66)
                    }
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
            appViewModel.logout()
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
            }
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 14))
        }
    }
}

struct UserRow: View {
    let user: InstagramUser

    var body: some View {
        HStack(spacing: 12) {
            Color(.tertiarySystemBackground)
                .frame(width: 44, height: 44)
                .overlay {
                    AsyncImage(url: URL(string: user.profilePicURL)) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(user.username)
                        .font(.subheadline.weight(.semibold))
                    if user.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                Text(user.fullName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let count = user.followerCount {
                Text(formatCount(count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}
