import SwiftUI
import UIKit

@main
struct MTeamPTApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .onAppear {
                    setupAppearance()
                }
        }
    }
    
    private func setupAppearance() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.label]
        UINavigationBar.appearance().tintColor = UIColor.systemBlue
        
        // 修复iPad iOS 15 Button触摸响应问题
        UIScrollView.appearance().delaysContentTouches = false
    }
}

class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var apiKey: String = ""
    @Published var showOnboarding: Bool = false
    
    init() {
        checkAuthentication()
    }
    
    private func checkAuthentication() {
        if let savedKey = KeychainManager.shared.getAPIKey() {
            apiKey = savedKey
            isAuthenticated = true
        } else {
            showOnboarding = true
        }
    }
    
    func saveAPIKey(_ key: String) {
        // 清理密钥格式
        let cleanedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\\\s+", with: "", options: .regularExpression)
        
        KeychainManager.shared.saveAPIKey(cleanedKey)
        apiKey = cleanedKey
        isAuthenticated = true
        showOnboarding = false
    }
    
    func logout() {
        KeychainManager.shared.deleteAPIKey()
        apiKey = ""
        isAuthenticated = false
    }
}

class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme? = nil
    @Published var accentColor: Color = .blue
    
    init() {
        loadThemePreferences()
    }
    
    private func loadThemePreferences() {
        if let savedScheme = UserDefaults.standard.string(forKey: "colorScheme") {
            switch savedScheme {
            case "dark":
                colorScheme = .dark
            case "light":
                colorScheme = .light
            default:
                colorScheme = nil
            }
        }
    }
    
    func setColorScheme(_ scheme: ColorScheme?) {
        colorScheme = scheme
        let schemeString = scheme == .dark ? "dark" : scheme == .light ? "light" : "system"
        UserDefaults.standard.set(schemeString, forKey: "colorScheme")
    }
}