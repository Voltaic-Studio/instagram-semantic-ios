import SwiftUI

struct ContentView: View {
    @State private var appViewModel = AppViewModel()

    var body: some View {
        Group {
            if !appViewModel.hasCompletedOnboarding {
                OnboardingView {
                    withAnimation(.smooth(duration: 0.5)) {
                        appViewModel.completeOnboarding()
                    }
                }
                .transition(.opacity)
            } else if !appViewModel.isLoggedIn {
                LoginView(viewModel: appViewModel)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                HomeView(appViewModel: appViewModel)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.smooth(duration: 0.4), value: appViewModel.hasCompletedOnboarding)
        .animation(.smooth(duration: 0.4), value: appViewModel.isLoggedIn)
        .onAppear {
            appViewModel.checkSession()
        }
    }
}
