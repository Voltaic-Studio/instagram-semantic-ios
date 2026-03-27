import SwiftUI

struct InstagramLoginView: View {
    @Bindable var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var twoFactorCode: String = ""
    @State private var showsPassword: Bool = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case username
        case password
        case twoFactor
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    VStack(spacing: 12) {
                        Text("Connect Instagram")
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("Log in to sync your followers and search your network.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)

                    VStack(spacing: 14) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.top, 1)

                            Text("Instagram may send a login alert mentioning a new device like 6T Dev. That’s expected during connect.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(.rect(cornerRadius: 14))

                        textField("Username", text: $username, field: .username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        HStack(spacing: 12) {
                            Group {
                                if showsPassword {
                                    TextField("Password", text: $password)
                                } else {
                                    SecureField("Password", text: $password)
                                }
                            }
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                            Button {
                                showsPassword.toggle()
                            } label: {
                                Image(systemName: showsPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 56)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(.rect(cornerRadius: 14))
                        .onSubmit {
                            focusedField = .twoFactor
                        }

                        textField("2FA Code (optional)", text: $twoFactorCode, field: .twoFactor)
                            .keyboardType(.numberPad)

                        Button {
                            print("[InstagramLoginView] Connect Account tapped backend=\(Config.backendBaseURL)")
                            Task {
                                await viewModel.login(
                                    username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                                    password: password,
                                    twoFactorCode: twoFactorCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? nil
                                        : twoFactorCode.trimmingCharacters(in: .whitespacesAndNewlines)
                                )
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.black)
                                }
                                Text(viewModel.isLoading ? "Connecting..." : "Connect Account")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .clipShape(.rect(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .disabled(viewModel.isLoading || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                focusedField = .username
            }
            .onChange(of: viewModel.isLoggedIn) { _, isLoggedIn in
                if isLoggedIn {
                    dismiss()
                }
            }
        }
    }

    private func textField(_ title: String, text: Binding<String>, field: Field) -> some View {
        TextField(title, text: text)
            .focused($focusedField, equals: field)
            .submitLabel(field == .username ? .next : .done)
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 14))
            .onSubmit {
                switch field {
                case .username:
                    focusedField = .password
                case .password:
                    focusedField = .twoFactor
                case .twoFactor:
                    focusedField = nil
                }
            }
    }
}
