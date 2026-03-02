import SwiftUI

struct OnboardingView: View {
    @Bindable var viewModel: AppViewModel

    @State private var appeared: Bool = false
    @State private var floatingOffsets: [CGSize] = (0..<30).map { _ in
        CGSize(width: CGFloat.random(in: -200...200), height: CGFloat.random(in: -450...450))
    }
    @State private var floatingScales: [Double] = (0..<30).map { _ in Double.random(in: 0.4...1.4) }
    @State private var floatingRotations: [Double] = (0..<30).map { _ in Double.random(in: -15...15) }
    @State private var animationPhase: Bool = false
    @State private var showLoginFields: Bool = false
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var twoFactorCode: String = ""
    @State private var showTwoFactor: Bool = false
    @FocusState private var focusedField: LoginField?

    @Environment(\.colorScheme) private var colorScheme

    private enum LoginField {
        case username, password, twoFactor
    }

    private let avatarURLs: [String] = (1...30).map { "https://i.pravatar.cc/120?img=\($0 % 70)" }
    private let avatarSizes: [CGFloat] = (0..<30).map { _ in CGFloat([42, 48, 54, 60, 66, 72, 50, 56, 44, 68].randomElement()!) }

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack {
            backgroundLayer

            floatingAvatars

            gradientOverlay

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)

                    brandingSection
                        .padding(.bottom, 32)

                    instagramLoginCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    footerText
                        .padding(.bottom, 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                showLoginFields = true
            }
            startFloating()
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

    private var backgroundLayer: some View {
        Group {
            if isDark {
                Color.black.ignoresSafeArea()
            } else {
                Color(.systemBackground).ignoresSafeArea()
            }
        }
    }

    private var gradientOverlay: some View {
        LinearGradient(
            stops: [
                .init(color: (isDark ? Color.black : Color(.systemBackground)).opacity(0), location: 0),
                .init(color: (isDark ? Color.black : Color(.systemBackground)).opacity(0.4), location: 0.25),
                .init(color: (isDark ? Color.black : Color(.systemBackground)).opacity(0.88), location: 0.55),
                .init(color: isDark ? Color.black : Color(.systemBackground), location: 0.75)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var brandingSection: some View {
        VStack(spacing: 14) {
            Text("INSTASEARCH")
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .tracking(6)
                .foregroundStyle(isDark ? .white.opacity(0.5) : .secondary)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            Text("Find Anyone.\nKnow Everyone.")
                .font(.system(size: 36, weight: .black))
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    isDark
                        ? AnyShapeStyle(LinearGradient(
                            colors: [.white, .white.opacity(0.8), .purple.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        : AnyShapeStyle(LinearGradient(
                            colors: [.primary, .primary.opacity(0.8), .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Text("Semantic search across your followers.\nAI-powered. Instant. Unhinged.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
        }
        .padding(.horizontal, 32)
    }

    private var instagramLoginCard: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                loginField(
                    icon: "person",
                    placeholder: "Instagram Username",
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

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.9))
                    .transition(.opacity)
            }

            instagramButton

            Button {
                withAnimation(.snappy) {
                    showTwoFactor.toggle()
                }
            } label: {
                Text(showTwoFactor ? "Hide 2FA" : "I have 2FA enabled")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 4) {
                Text("Your credentials are sent to your backend only.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("We never store passwords on device.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(isDark ? Color.white.opacity(0.06) : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isDark ? .white.opacity(0.08) : .primary.opacity(0.06), lineWidth: 1)
        )
        .opacity(showLoginFields ? 1 : 0)
        .offset(y: showLoginFields ? 0 : 30)
    }

    private var instagramButton: some View {
        Button {
            Task {
                await viewModel.login(
                    username: username,
                    password: password,
                    twoFactorCode: showTwoFactor ? twoFactorCode : nil
                )
            }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "camera.fill")
                        .font(.body.bold())
                }
                Text(viewModel.isLoading ? "Connecting..." : "Log in with Instagram")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.51, green: 0.23, blue: 0.72),
                        Color(red: 0.83, green: 0.18, blue: 0.42),
                        Color(red: 0.99, green: 0.44, blue: 0.16)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(.rect(cornerRadius: 14))
            .shadow(color: Color(red: 0.83, green: 0.18, blue: 0.42).opacity(0.35), radius: 12, y: 6)
        }
        .disabled(username.isEmpty || password.isEmpty || viewModel.isLoading)
        .opacity(username.isEmpty || password.isEmpty ? 0.6 : 1)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.isLoading)
    }

    private var footerText: some View {
        Text("your followers are about to be indexed 👀")
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.tertiary)
            .opacity(appeared ? 1 : 0)
            .padding(.top, 8)
    }

    private var floatingAvatars: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2.8)
            ForEach(0..<30, id: \.self) { i in
                avatarBubble(index: i, center: center)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func avatarBubble(index: Int, center: CGPoint) -> some View {
        let size = avatarSizes[index]

        return Color(isDark ? .secondarySystemBackground : .tertiarySystemFill)
            .frame(width: size, height: size)
            .overlay {
                AsyncImage(url: URL(string: avatarURLs[index])) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    }
                }
                .allowsHitTesting(false)
            }
            .clipShape(Circle())
            .overlay(
                Circle().stroke(
                    isDark ? .white.opacity(0.12) : .primary.opacity(0.08),
                    lineWidth: 1
                )
            )
            .shadow(color: .black.opacity(isDark ? 0.3 : 0.08), radius: 8, y: 4)
            .scaleEffect(floatingScales[index])
            .rotationEffect(.degrees(floatingRotations[index]))
            .position(
                x: center.x + floatingOffsets[index].width,
                y: center.y + floatingOffsets[index].height
            )
            .opacity(appeared ? Double.random(in: 0.25...0.7) : 0)
            .blur(radius: abs(floatingOffsets[index].height) > 280 ? 4 : (abs(floatingOffsets[index].height) > 180 ? 2 : 0))
            .animation(.easeOut(duration: 1.5).delay(Double(index) * 0.06), value: appeared)
    }

    private func loginField(icon: String, placeholder: String, text: Binding<String>, field: LoginField, isSecure: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
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
        .padding(14)
        .background(isDark ? Color.white.opacity(0.07) : Color(.systemBackground))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDark ? .white.opacity(0.1) : .primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func startFloating() {
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            animationPhase.toggle()
        }

        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 3.5)) {
                    for i in 0..<30 {
                        floatingOffsets[i] = CGSize(
                            width: floatingOffsets[i].width + CGFloat.random(in: -25...25),
                            height: floatingOffsets[i].height + CGFloat.random(in: -25...25)
                        )
                        floatingRotations[i] += Double.random(in: -5...5)
                    }
                }
            }
        }
    }
}
