// Config.swift - Auto-generated at build time
// Environment variables from Project Settings are injected here
//
// Usage: Config.YOUR_ENV_NAME
// Example: If you set MY_API_KEY in Environment Variables,
//          use Config.MY_API_KEY in your code

import Foundation

enum Config {
    static let backendBaseURL = "https://0899-65-200-105-218.ngrok-free.app"
    static let authCallbackScheme = ProcessInfo.processInfo.environment["AUTH_CALLBACK_SCHEME"] ?? "instasemantic"
    static let authCallbackHost = ProcessInfo.processInfo.environment["AUTH_CALLBACK_HOST"] ?? "auth-callback"
}
