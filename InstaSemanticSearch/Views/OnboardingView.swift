import SwiftUI

struct OnboardingView: View {
    @Bindable var viewModel: AppViewModel

    @State private var appeared: Bool = false
    @State private var floatingOffsets: [CGSize] = (0..<35).map { _ in
        CGSize(width: CGFloat.random(in: -200...200), height: CGFloat.random(in: -400...400))
    }
    @State private var floatingScales: [Double] = (0..<35).map { _ in Double.random(in: 0.5...1.5) }
    @State private var floatingRotations: [Double] = (0..<35).map { _ in Double.random(in: -12...12) }
    @State private var animationPhase: Bool = false
    @State private var buttonPressed: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    private let avatarURLs: [String] = [
        "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1521119989659-a83eee488004?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1524638431109-93d95c968f03?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1514315384763-ba401779410f?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1519345182560-3f2917c472ef?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1536766768598-e09213fdcf22?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1516726817505-f5ed825624d8?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1504257432389-52343af06ae3?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1463453091185-61582044d556?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1496440737103-cd596325d314?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1519699047748-de8e457a634e?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1518577915332-c2a19f149a75?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1507081323647-4d250478b919?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1523264653568-d3d4685e475d?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1498551172505-8ee7ad69f235?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1513956589380-bad6acb9b9d4?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1524502397800-2eeaad7c3fe5?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1530785602389-07594beb8b73?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1542206395-9feb3edaa68d?w=120&h=120&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=120&h=120&fit=crop&crop=face"
    ]

    private let avatarSizes: [CGFloat] = (0..<35).map { _ in CGFloat([44, 50, 56, 62, 68, 74, 52, 58, 46, 70].randomElement()!) }

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack {
            backgroundLayer

            floatingAvatars

            bottomContent
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                appeared = true
            }
            startFloating()
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

    private var bottomContent: some View {
        VStack {
            Spacer()

            VStack(spacing: 0) {
                LinearGradient(
                    stops: [
                        .init(color: (isDark ? Color.black : Color(.systemBackground)).opacity(0), location: 0),
                        .init(color: (isDark ? Color.black : Color(.systemBackground)).opacity(0.7), location: 0.3),
                        .init(color: isDark ? Color.black : Color(.systemBackground), location: 0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)

                VStack(spacing: 20) {
                    brandingSection

                    instagramButton
                        .padding(.horizontal, 32)

                    footerText
                }
                .padding(.bottom, 50)
                .background(isDark ? Color.black : Color(.systemBackground))
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var brandingSection: some View {
        VStack(spacing: 12) {
            Text("INSTASEARCH")
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .tracking(6)
                .foregroundStyle(isDark ? .white.opacity(0.5) : .secondary)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            Text("Find Anyone.\nKnow Everyone.")
                .font(.system(size: 34, weight: .black))
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

    private var instagramButton: some View {
        Button {
            buttonPressed = true
            Task {
                await viewModel.login(username: "", password: "")
            }
        } label: {
            HStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image("instagram_icon")
                        .resizable()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(.white)
                        .overlay {
                            instagramIconView
                        }
                }
                Text(viewModel.isLoading ? "Connecting..." : "Log in with Instagram")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.40, green: 0.13, blue: 0.67),
                        Color(red: 0.83, green: 0.18, blue: 0.42),
                        Color(red: 0.99, green: 0.44, blue: 0.16),
                        Color(red: 1.0, green: 0.72, blue: 0.07)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(.rect(cornerRadius: 16))
            .shadow(color: Color(red: 0.83, green: 0.18, blue: 0.42).opacity(0.4), radius: 16, y: 8)
        }
        .scaleEffect(buttonPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3), value: buttonPressed)
        .disabled(viewModel.isLoading)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.isLoading)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onChange(of: buttonPressed) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    buttonPressed = false
                }
            }
        }
    }

    private var instagramIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .stroke(.white, lineWidth: 1.8)
                .frame(width: 18, height: 18)

            Circle()
                .stroke(.white, lineWidth: 1.8)
                .frame(width: 8, height: 8)

            Circle()
                .fill(.white)
                .frame(width: 2.5, height: 2.5)
                .offset(x: 4.5, y: -4.5)
        }
        .frame(width: 22, height: 22)
    }

    private var footerText: some View {
        Text("your followers are about to be indexed 👀")
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.tertiary)
            .opacity(appeared ? 1 : 0)
            .padding(.top, 4)
    }

    private var floatingAvatars: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.35)
            ForEach(0..<35, id: \.self) { i in
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
                    isDark ? .white.opacity(0.15) : .primary.opacity(0.08),
                    lineWidth: 1.5
                )
            )
            .shadow(color: .black.opacity(isDark ? 0.35 : 0.1), radius: 8, y: 4)
            .scaleEffect(floatingScales[index])
            .rotationEffect(.degrees(floatingRotations[index]))
            .position(
                x: center.x + floatingOffsets[index].width,
                y: center.y + floatingOffsets[index].height
            )
            .opacity(appeared ? Double.random(in: 0.4...0.95) : 0)
            .animation(.easeOut(duration: 1.5).delay(Double(index) * 0.05), value: appeared)
    }

    private func startFloating() {
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            animationPhase.toggle()
        }

        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 3.5)) {
                    for i in 0..<35 {
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
