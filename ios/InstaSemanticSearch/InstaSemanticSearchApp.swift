import SwiftUI

@main
struct InstaSemanticSearchApp: App {
    @State private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(appViewModel: appViewModel)
                .onOpenURL { url in
                    appViewModel.handleAuthCallback(url)
                }
        }
    }
}
