import SwiftUI

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

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 28) {
                    headerBar

                    heroSection

                    scopeSelector

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
                Text("semantic search engine")
                    .font(.system(.caption, design: .monospaced))
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

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.12),
                                Color.indigo.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.primary.opacity(0.06), lineWidth: 1)
                    )

                VStack(spacing: 12) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.purple.opacity(0.7))
                        .symbolEffect(.pulse, isActive: true)

                    Text("Ask anything about\nyour network")
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)

                    Text("\"find me blonde girls\" · \"mutual photographers\"\n\"people who don't follow me back\"")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(28)
            }

            Button {
                showSearch = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                    Text("Search your network...")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "mic.fill")
                        .foregroundStyle(.tertiary)
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
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private var scopeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SEARCH SCOPE")
                .font(.system(.caption2, design: .monospaced, weight: .semibold))
                .foregroundStyle(.secondary)

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
        }
        .opacity(appeared ? 1 : 0)
    }

    private var quickSearchChips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TRY ASKING")
                .font(.system(.caption2, design: .monospaced, weight: .semibold))
                .foregroundStyle(.secondary)

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
                            .font(.system(.caption2, design: .monospaced, weight: .semibold))
                            .foregroundStyle(.secondary)
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
                searchButtonContent
                    .padding(.trailing, 20)
                    .padding(.bottom, 32)
            }
        }
    }

    @ViewBuilder
    private var searchButtonContent: some View {
        Button {
            showSearch = true
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        colors: [.purple, .indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: .purple.opacity(0.4), radius: 12, y: 6)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: showSearch)
    }
}
