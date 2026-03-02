import SwiftUI

struct SearchSheetView: View {
    @Bindable var viewModel: SearchViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    @State private var appeared: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        searchBar

                        scopePicker

                        if viewModel.isSearching {
                            loadingState
                        } else if !viewModel.results.isEmpty {
                            resultsSection
                        } else if viewModel.query.isEmpty {
                            suggestionsSection
                        } else if viewModel.errorMessage != nil {
                            errorState
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .onAppear {
            isSearchFocused = true
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
        .presentationContentInteraction(.scrolls)
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkle.magnifyingglass")
                .foregroundStyle(.purple.opacity(0.6))

            TextField("Ask anything about your network...", text: $viewModel.query)
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    Task { await viewModel.search() }
                }

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.clearResults()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.purple.opacity(isSearchFocused ? 0.3 : 0), lineWidth: 1.5)
        )
        .animation(.snappy, value: isSearchFocused)
    }

    private var scopePicker: some View {
        HStack(spacing: 8) {
            ForEach(SearchScope.allCases, id: \.self) { scope in
                Button {
                    withAnimation(.snappy) {
                        viewModel.searchScope = scope
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: scope.icon)
                            .font(.caption)
                        Text(scope.displayName)
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        viewModel.searchScope == scope
                            ? Color.purple.opacity(0.12)
                            : Color(.tertiarySystemBackground)
                    )
                    .foregroundStyle(
                        viewModel.searchScope == scope ? .purple : .secondary
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching across profiles...")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var errorState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 40)
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(.secondary)
            Text(viewModel.errorMessage ?? "Something went wrong")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                Task { await viewModel.search() }
            }
            .font(.subheadline.weight(.semibold))
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(viewModel.results.count) RESULTS")
                    .font(.system(.caption2, design: .monospaced, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            ForEach(Array(viewModel.results.enumerated()), id: \.element.id) { index, result in
                SearchResultRow(result: result)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(.spring(response: 0.4).delay(Double(index) * 0.04), value: appeared)
            }
        }
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !viewModel.recentQueries.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("RECENT")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(viewModel.recentQueries.prefix(5), id: \.self) { query in
                        Button {
                            viewModel.query = query
                            Task { await viewModel.search() }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                Text(query)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("SUGGESTIONS")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(viewModel.suggestedQueries, id: \.self) { query in
                    Button {
                        viewModel.query = query
                        Task { await viewModel.search() }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.subheadline)
                                .foregroundStyle(.purple.opacity(0.6))
                            Text(query)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        HStack(spacing: 14) {
            Color(.tertiarySystemBackground)
                .frame(width: 52, height: 52)
                .overlay {
                    AsyncImage(url: URL(string: result.user.profilePicURL)) { phase in
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

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(result.user.username)
                        .font(.subheadline.weight(.semibold))
                    if result.user.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }

                Text(result.user.fullName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let tags = result.tags, !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(.caption2, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let score = result.score {
                    Text("\(Int(score * 100))%")
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundStyle(.purple)
                }

                if let matchType = result.matchType {
                    Text(matchType.uppercased())
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
}
