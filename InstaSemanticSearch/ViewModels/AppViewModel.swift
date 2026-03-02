import SwiftUI

@Observable
final class AppViewModel {
    var isLoggedIn: Bool = false
    var currentUser: InstagramUser?
    var isLoading: Bool = false
    var errorMessage: String?

    let apiService = APIService()

    func checkSession() {
        apiService.loadStoredToken()
        isLoggedIn = apiService.isAuthenticated
    }

    func login(username: String, password: String, twoFactorCode: String? = nil) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await apiService.login(username: username, password: password, twoFactorCode: twoFactorCode)
            if response.success, let token = response.token {
                apiService.setToken(token)
                currentUser = response.user
                isLoggedIn = true
            } else {
                errorMessage = response.message ?? "Login failed"
            }
        } catch {
            errorMessage = "Connection error. Check your backend URL."
        }
        isLoading = false
    }

    func logout() {
        apiService.clearToken()
        isLoggedIn = false
        currentUser = nil
    }
}
