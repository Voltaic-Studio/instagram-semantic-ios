import SwiftUI

struct ContentView: View {
    @Bindable var appViewModel: AppViewModel

    var body: some View {
        Group {
            if appViewModel.isLoggedIn {
                HomeView(appViewModel: appViewModel)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                OnboardingView(viewModel: appViewModel)
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.5), value: appViewModel.isLoggedIn)
        .onAppear {
            appViewModel.checkSession()
        }
    }
}
