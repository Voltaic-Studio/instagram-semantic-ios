import SwiftUI

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

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        _searchVM = State(initialValue: SearchViewModel(apiService: appViewModel.apiService))
        _profileVM = State(initialValue: ProfileViewModel(apiService: appViewModel.apiService))
    }

    private let mockFollowers: [(id: String, username: String, fullName: String, picIndex: Int, verified: Bool, followerCount: Int)] = [
        ("1", "emma.creates", "Emma Johnson", 10, true, 24300),
        ("2", "jake_photo", "Jake Williams", 11, false, 8900),
        ("3", "sophia.fit", "Sophia Chen", 12, true, 142000),
        ("4", "alex.travel", "Alex Rivera", 13, false, 3200),
        ("5", "mia.art", "Mia Thompson", 14, false, 18700),
        ("6", "noah.dev", "Noah Kim", 15, true, 56400),
        ("7", "olivia.style", "Olivia Davis", 16, false, 9100),
        ("8", "liam.music", "Liam Garcia", 17, false, 31200),
        ("9", "ava.cooks", "Ava Martinez", 18, false, 7600),
        ("10", "ethan.game", "Ethan Brown", 19, false, 44500),
        ("11", "luna.yoga", "Luna Patel", 20, true, 89000),
        ("12", "mason.tech", "Mason Lee", 21, false, 12400),
        ("13", "zoe.vibes", "Zoe Anderson", 22, false, 5800),
        ("14", "kai.beats", "Kai Nakamura", 23, false, 27600),
        ("15", "iris.design", "Iris Okafor", 24, false, 15300),
        ("16", "leo.skate", "Leo Rossi", 25, false, 41200),
    ]

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 24) {
                    headerBar

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
        .task {
            await profileVM.loadData()
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
                    .font(.system(size: 28, weight: .black))
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
                Text("YOUR PEOPLE")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Spacer()
                Text("\(mockFollowers.count) followers")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(Array(mockFollowers.enumerated()), id: \.element.id) { index, follower in
                    followerCard(follower: follower, index: index)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    private func followerCard(follower: (id: String, username: String, fullName: String, picIndex: Int, verified: Bool, followerCount: Int), index: Int) -> some View {
        VStack(spacing: 8) {
            Color(.tertiarySystemBackground)
                .frame(width: 72, height: 72)
                .overlay {
                    AsyncImage(url: URL(string: "https://i.pravatar.cc/150?img=\(follower.picIndex)")) { phase in
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
                            LinearGradient(
                                colors: follower.verified
                                    ? [.purple, .pink, .orange]
                                    : [.primary.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: follower.verified ? 2 : 1
                        )
                )

            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Text(follower.username)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                    if follower.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.blue)
                    }
                }

                Text(formatCount(follower.followerCount))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
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
                        .foregroundStyle(.primary)
                        .frame(width: 60, height: 60)
                        .adaptiveGlass()
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: showSearch)
                .padding(.trailing, 20)
                .padding(.bottom, 32)
            }
        }
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
