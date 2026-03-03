import SwiftUI
import UIKit

extension View {
    @ViewBuilder
    func adaptiveGlass() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(in: .circle)
        } else {
            self
                .background(.ultraThinMaterial, in: Circle())
                .shadow(color: .primary.opacity(0.15), radius: 12, y: 6)
        }
    }
}

struct HomeView: View {
    @Bindable var appViewModel: AppViewModel

    @State private var showSearch: Bool = false
    @State private var showProfile: Bool = false
    @State private var searchVM: SearchViewModel
    @State private var profileVM: ProfileViewModel
    @State private var appeared: Bool = false
    @State private var lastHandledSyncStatus: String?
    @State private var activeSheet: HomeAccountSheet?

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        _searchVM = State(initialValue: SearchViewModel(apiService: appViewModel.apiService))
        _profileVM = State(initialValue: ProfileViewModel(apiService: appViewModel.apiService))
    }

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 24) {
                    headerBar

                    syncBanner

                    statsOverview

                    searchBar

                    scopeSelector

                    followerGrid

                    quickSearchChips

                    recentSearches

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)

            floatingSearchButton
        }
        .sheet(isPresented: $showSearch) {
            SearchSheetView(viewModel: searchVM)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showProfile) {
            ProfileOverlayView(viewModel: profileVM, appViewModel: appViewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $activeSheet) { sheet in
            AccountListSheetView(title: sheet.title, users: sheet.users)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task {
            await profileVM.loadData()
            await appViewModel.pollSyncStatus()
        }
        .task(id: appViewModel.syncStatus?.status) {
            let status = appViewModel.syncStatus?.status
            if lastHandledSyncStatus != status, status == "ready" {
                await profileVM.loadData(force: true)
            }
            lastHandledSyncStatus = status
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }

    private var backgroundGradient: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    .clear, .clear, .clear,
                    .purple.opacity(0.05), .clear, .indigo.opacity(0.04),
                    .clear, .purple.opacity(0.03), .clear
                ]
            )
            .ignoresSafeArea()
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("InstaSearch")
                    .font(.system(size: 30, weight: .semibold, design: .default))
                Text("search through your followers ✨")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showProfile = true
            } label: {
                profileAvatar
            }
        }
        .padding(.top, 12)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }

    @ViewBuilder
    private var syncBanner: some View {
        if let syncStatus = appViewModel.syncStatus, syncStatus.isActive {
            HStack(alignment: .center, spacing: 14) {
                Text("🫧")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 6) {
                    Text(syncStatus.message ?? "Pulling all your followers to then start search!")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Will take a minute or less")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(syncStatus.progress), total: 100)
                        .progressViewStyle(.linear)
                        .tint(.primary.opacity(0.85))
                }

                Spacer(minLength: 0)

                Text("\(syncStatus.progress)%")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.06), radius: 14, y: 8)
            .opacity(appeared ? 1 : 0)
        }
    }

    private var profileAvatar: some View {
        Group {
            if let user = appViewModel.currentUser {
                Color(.tertiarySystemBackground)
                    .frame(width: 42, height: 42)
                    .overlay {
                        AsyncImage(url: URL(string: user.profilePicURL)) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.primary.opacity(0.1), lineWidth: 1))
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var searchBar: some View {
        Button {
            showSearch = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.purple.opacity(0.6))
                Text("find anyone...")
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple.opacity(0.4))
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var statsOverview: some View {
        let stats = profileVM.stats
        let items: [(value: String, label: String, icon: String, color: Color)] = [
            ("\(stats?.followers ?? 0)", "Followers", "person.2.fill", .purple),
            ("\(stats?.following ?? 0)", "Following", "person.badge.plus", .blue),
            ("\(stats?.mutuals ?? 0)", "Follow you back", "arrow.triangle.2.circlepath.circle.fill", .green),
            ("\(stats?.nonMutuals ?? 0)", "Doesn't follow back", "person.crop.circle.badge.xmark", .orange)
        ]

        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(0..<2, id: \.self) { index in
                    statCard(item: items[index], index: index)
                }
            }
            HStack(spacing: 10) {
                ForEach(2..<4, id: \.self) { index in
                    statCard(item: items[index], index: index)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private func statCard(item: (value: String, label: String, icon: String, color: Color), index: Int) -> some View {
        Button {
            activeSheet = sheetForStatsLabel(item.label)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundStyle(item.color.opacity(0.8))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.value)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text(item.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .animation(.spring(response: 0.4).delay(Double(index) * 0.06), value: appeared)
    }

    private var scopeSelector: some View {
        HStack(spacing: 12) {
            ForEach(SearchScope.allCases, id: \.self) { scope in
                Button {
                    withAnimation(.snappy) {
                        searchVM.searchScope = scope
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: scope.icon)
                            .font(.subheadline)
                        Text(scope.displayName)
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        searchVM.searchScope == scope
                            ? Color.primary.opacity(0.08)
                            : Color(.secondarySystemBackground)
                    )
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                searchVM.searchScope == scope
                                    ? Color.primary.opacity(0.15)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private var followerGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(searchVM.searchScope == .following ? "WHO YOU FOLLOW" : "WHO FOLLOWS YOU")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Spacer()
                Text("\(displayedUsers.count) accounts")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if profileVM.isLoading && displayedUsers.isEmpty {
                loadingGrid
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    ForEach(Array(displayedUsers.prefix(15).enumerated()), id: \.element.id) { index, user in
                        followerCard(follower: user, index: index)
                    }

                    if displayedUsers.count > 15 {
                        seeMoreCard
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    private var loadingGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 132)
                        .overlay {
                            ProgressView()
                                .controlSize(.small)
                        }
                }
            }
            Text("Loading accounts...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var displayedUsers: [InstagramUser] {
        switch searchVM.searchScope {
        case .following:
            return profileVM.following
        case .followers:
            return profileVM.followers
        }
    }

    private func followerCard(follower: InstagramUser, index: Int) -> some View {
        Button {
            openInstagramProfile(for: follower)
        } label: {
            VStack(spacing: 8) {
                Color(.tertiarySystemBackground)
                    .frame(width: 72, height: 72)
                    .overlay {
                        AsyncImage(url: URL(string: follower.profilePicURL)) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                ProgressView()
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                follower.isVerified == true
                                    ? Color(red: 0/255, green: 149/255, blue: 246/255).opacity(0.35)
                                    : .primary.opacity(0.08),
                                lineWidth: follower.isVerified == true ? 2 : 1
                            )
                    )

                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        Text(follower.username)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                        if follower.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color(red: 0/255, green: 149/255, blue: 246/255))
                        }
                    }

                    Text(follower.followsBack == true ? "Follows you" : "Doesn't follow back")
                        .font(.caption2)
                        .foregroundStyle(follower.followsBack == true ? .green : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 14))
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .animation(.spring(response: 0.45).delay(Double(index) * 0.03), value: appeared)
        }
        .buttonStyle(.plain)
    }

    private var seeMoreCard: some View {
        Button {
            activeSheet = HomeAccountSheet(
                title: searchVM.searchScope == .following ? "Who You Follow" : "Who Follows You",
                users: displayedUsers
            )
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("See more")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 132)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func sheetForStatsLabel(_ label: String) -> HomeAccountSheet {
        switch label {
        case "Followers":
            return HomeAccountSheet(title: "Who Follows You", users: profileVM.followers)
        case "Following":
            return HomeAccountSheet(title: "Who You Follow", users: profileVM.following)
        case "Follow you back":
            return HomeAccountSheet(title: "Follow You Back", users: profileVM.mutuals)
        default:
            return HomeAccountSheet(title: "Following That Don't Follow Back", users: profileVM.nonMutuals)
        }
    }

    private var quickSearchChips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TRY ASKING")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(1)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(searchVM.suggestedQueries.prefix(5), id: \.self) { query in
                        Button {
                            searchVM.query = query
                            showSearch = true
                        } label: {
                            Text(query)
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .contentMargins(.horizontal, 0)
            .scrollIndicators(.hidden)
        }
        .opacity(appeared ? 1 : 0)
    }

    private var recentSearches: some View {
        Group {
            if !searchVM.recentQueries.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("RECENT")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .tracking(1)
                        Spacer()
                    }

                    ForEach(searchVM.recentQueries.prefix(5), id: \.self) { query in
                        Button {
                            searchVM.query = query
                            showSearch = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                Text(query)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var floatingSearchButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title2.bold())
                        .foregroundStyle(.purple.opacity(0.8))
                        .frame(width: 60, height: 60)
                        .adaptiveGlass()
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: showSearch)
                .padding(.trailing, 20)
                .padding(.bottom, 32)
            }
        }
    }

    private func openInstagramProfile(for user: InstagramUser) {
        if let appURL = user.instagramAppURL {
            UIApplication.shared.open(appURL) { accepted in
                if !accepted, let webURL = user.instagramWebURL {
                    UIApplication.shared.open(webURL)
                }
            }
        } else if let webURL = user.instagramWebURL {
            UIApplication.shared.open(webURL)
        }
    }

}

private struct HomeAccountSheet: Identifiable {
    let id = UUID()
    let title: String
    let users: [InstagramUser]
}
