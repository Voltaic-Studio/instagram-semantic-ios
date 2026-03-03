import SwiftUI

@Observable
final class AppViewModel {
    var isLoggedIn: Bool = false
    var currentUser: InstagramUser?
    var isLoading: Bool = false
    var errorMessage: String?
    var syncStatus: SyncStatus?

    let apiService = APIService()

    func checkSession() {
        apiService.loadStoredToken()
        isLoggedIn = apiService.isAuthenticated
        guard isLoggedIn else { return }
        Task {
            await loadCurrentUser()
        }
    }

    func login(username: String, password: String, twoFactorCode: String? = nil) async {
        print("[AppViewModel] login() username=\(username) backend=\(Config.backendBaseURL)")
        isLoading = true
        errorMessage = nil
        do {
            let response = try await apiService.login(username: username, password: password, twoFactorCode: twoFactorCode)
            if response.success, let token = response.token {
                print("[AppViewModel] login() success")
                apiService.setToken(token)
                currentUser = response.user
                isLoggedIn = true
                Task {
                    await pollSyncStatus()
                }
            } else {
                print("[AppViewModel] login() backend returned failure: \(response.message ?? "unknown")")
                errorMessage = response.message ?? "Login failed"
            }
        } catch {
            print("[AppViewModel] login() threw error: \(error.localizedDescription)")
            errorMessage = "Connection error. Check your backend URL."
        }
        isLoading = false
    }

    func handleAuthCallback(_ url: URL) {
        guard url.scheme == Config.authCallbackScheme, url.host == Config.authCallbackHost else { return }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            errorMessage = "Invalid auth callback."
            isLoading = false
            return
        }
        guard let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
            errorMessage = "Missing auth token."
            isLoading = false
            return
        }

        apiService.setToken(token)
        isLoggedIn = true
        Task {
            await loadCurrentUser()
        }
    }

    @MainActor
    func loadCurrentUser() async {
        do {
            currentUser = try await apiService.fetchCurrentUser()
            errorMessage = nil
        } catch {
            if let apiError = error as? APIError, apiError.isUnauthorized {
                apiService.clearToken()
                isLoggedIn = false
                currentUser = nil
                errorMessage = "Session expired. Please log in again."
            } else {
                errorMessage = "Could not refresh your account right now."
            }
        }
        isLoading = false
    }

    @MainActor
    func refreshSyncStatus() async {
        do {
            syncStatus = try await apiService.fetchSyncStatus()
        } catch {
            print("[AppViewModel] refreshSyncStatus() failed: \(error.localizedDescription)")
        }
    }

    func pollSyncStatus() async {
        for _ in 0..<30 {
            await refreshSyncStatus()
            if syncStatus?.isActive != true {
                break
            }
            try? await Task.sleep(for: .seconds(2))
        }
    }

    func logout() {
        apiService.clearToken()
        isLoggedIn = false
        currentUser = nil
        syncStatus = nil
    }
}
