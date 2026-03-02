import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: AppViewModel

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var twoFactorCode: String = ""
    @State private var showTwoFactor: Bool = false
    @State private var appeared: Bool = false
    @FocusState private var focusedField: LoginField?

    private enum LoginField {
        case username, password, twoFactor
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    .black, .black, .black,
                    .purple.opacity(0.15), .black, .indigo.opacity(0.1),
                    .black, .purple.opacity(0.1), .black
                ]
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 60)

                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(.white.opacity(0.8))
                            .symbolEffect(.pulse, isActive: viewModel.isLoading)

                        Text("InstaSearch")
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.white)

                        Text("Sign in with your Instagram")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -20)

                    VStack(spacing: 16) {
                        loginField(
                            icon: "person",
                            placeholder: "Username",
                            text: $username,
                            field: .username,
                            isSecure: false
                        )

                        loginField(
                            icon: "lock",
                            placeholder: "Password",
                            text: $password,
                            field: .password,
                            isSecure: true
                        )

                        if showTwoFactor {
                            loginField(
                                icon: "number",
                                placeholder: "2FA Code",
                                text: $twoFactorCode,
                                field: .twoFactor,
                                isSecure: false
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.9))
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    }

                    Button {
                        Task {
                            await viewModel.login(
                                username: username,
                                password: password,
                                twoFactorCode: showTwoFactor ? twoFactorCode : nil
                            )
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.black)
                            }
                            Text(viewModel.isLoading ? "Connecting..." : "Sign In")
                                .font(.headline)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .clipShape(.rect(cornerRadius: 14))
                    }
                    .disabled(username.isEmpty || password.isEmpty || viewModel.isLoading)
                    .opacity(username.isEmpty || password.isEmpty ? 0.5 : 1)
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)

                    Button {
                        withAnimation(.snappy) {
                            showTwoFactor.toggle()
                        }
                    } label: {
                        Text(showTwoFactor ? "Hide 2FA" : "I have 2FA enabled")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    VStack(spacing: 8) {
                        Text("Your credentials are sent to your backend only.")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.25))
                        Text("We never store passwords on device.")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.25))
                    }
                    .padding(.top, 16)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
        .onSubmit {
            switch focusedField {
            case .username: focusedField = .password
            case .password:
                if showTwoFactor { focusedField = .twoFactor }
            default: break
            }
        }
    }

    private func loginField(icon: String, placeholder: String, text: Binding<String>, field: LoginField, isSecure: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: text)
                    .textContentType(.password)
                    .focused($focusedField, equals: field)
            } else {
                TextField(placeholder, text: text)
                    .textContentType(field == .username ? .username : .oneTimeCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: field)
            }
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(Color.white.opacity(0.08))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}
