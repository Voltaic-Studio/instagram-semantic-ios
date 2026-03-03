import SwiftUI

struct AccountListSheetView: View {
    let title: String
    let users: [InstagramUser]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if users.isEmpty {
                        ContentUnavailableView(
                            "No accounts yet",
                            systemImage: "person.slash",
                            description: Text("This list is still empty.")
                        )
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(users) { user in
                                AccountRow(user: user)
                                if user.id != users.last?.id {
                                    Divider().padding(.leading, 66)
                                }
                            }
                        }
                        .background(Color(.secondarySystemBackground))
                        .clipShape(.rect(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
    }
}

struct AccountRow: View {
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
