import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var appeared: Bool = false
    @State private var floatingOffsets: [CGSize] = (0..<20).map { _ in
        CGSize(width: CGFloat.random(in: -180...180), height: CGFloat.random(in: -400...400))
    }
    @State private var floatingScales: [Double] = (0..<20).map { _ in Double.random(in: 0.5...1.3) }
    @State private var animationPhase: Bool = false

    private let avatarURLs: [String] = (1...20).map { "https://i.pravatar.cc/120?img=\($0)" }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            floatingAvatars

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black.opacity(0.3), location: 0.3),
                    .init(color: .black.opacity(0.85), location: 0.65),
                    .init(color: .black, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Text("INSTASEARCH")
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .tracking(6)
                        .foregroundStyle(.white.opacity(0.5))
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    Text("Find Anyone.\nKnow Everyone.")
                        .font(.system(size: 38, weight: .black))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8), .purple.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    Text("Semantic search across your followers.\nAI-powered. Instant. Unhinged.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)
                }
                .padding(.horizontal, 32)

                Spacer()
                    .frame(height: 48)

                Button {
                    onComplete()
                } label: {
                    HStack(spacing: 8) {
                        Text("let's go")
                            .font(.system(.title3, design: .monospaced, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.title3.bold())
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.white, Color(white: 0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(.rect(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                .sensoryFeedback(.impact(weight: .medium), trigger: appeared)

                Spacer()
                    .frame(height: 20)

                Text("your followers are about to be indexed 👀")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                    .opacity(appeared ? 1 : 0)

                Spacer()
                    .frame(height: 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                appeared = true
            }
            startFloating()
        }
    }

    private var floatingAvatars: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2.5)
            ForEach(0..<20, id: \.self) { i in
                avatarBubble(index: i, center: center)
            }
        }
        .ignoresSafeArea()
    }

    private func avatarBubble(index: Int, center: CGPoint) -> some View {
        let size: CGFloat = CGFloat([50, 60, 44, 70, 55, 48, 64, 52, 58, 46, 62, 54, 68, 42, 56, 66, 50, 60, 44, 72][index])

        return Color(.secondarySystemBackground)
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
            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
            .scaleEffect(floatingScales[index])
            .position(
                x: center.x + floatingOffsets[index].width,
                y: center.y + floatingOffsets[index].height
            )
            .opacity(appeared ? Double.random(in: 0.3...0.7) : 0)
            .blur(radius: abs(floatingOffsets[index].height) > 250 ? 3 : 0)
            .animation(.easeOut(duration: 1.5).delay(Double(index) * 0.08), value: appeared)
    }

    private func startFloating() {
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            animationPhase.toggle()
        }

        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 4)) {
                    for i in 0..<20 {
                        floatingOffsets[i] = CGSize(
                            width: floatingOffsets[i].width + CGFloat.random(in: -30...30),
                            height: floatingOffsets[i].height + CGFloat.random(in: -30...30)
                        )
                    }
                }
            }
        }
    }
}
