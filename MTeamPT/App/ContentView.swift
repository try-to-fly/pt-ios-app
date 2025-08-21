import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    
    var body: some View {
        if appState.showOnboarding {
            OnboardingView()
                .environmentObject(appState)
        } else if appState.isAuthenticated {
            TabView(selection: $selectedTab) {
                SearchView()
                    .tabItem {
                        Label("搜索", systemImage: "magnifyingglass")
                    }
                    .tag(0)
                
                DownloadsView()
                    .tabItem {
                        Label("下载", systemImage: "arrow.down.circle")
                    }
                    .tag(1)
                
                SettingsView()
                    .tabItem {
                        Label("设置", systemImage: "gear")
                    }
                    .tag(2)
            }
            .accentColor(themeManager.accentColor)
        } else {
            OnboardingView()
                .environmentObject(appState)
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var apiKey: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "film.stack")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 10) {
                    Text("欢迎使用 M-Team PT")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("开始前，请配置您的 API 密钥")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API 密钥")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("输入您的 API 密钥", text: $apiKey)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    Button(action: validateAndSaveAPIKey) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("开始使用")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(apiKey.isEmpty || isLoading)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("如何获取 API 密钥？")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("登录 M-Team 网站 → 控制面板 → API 设置")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func validateAndSaveAPIKey() {
        isLoading = true
        
        Task {
            let isValid = await APIService.shared.validateAPIKey(apiKey)
            
            await MainActor.run {
                if isValid {
                    appState.saveAPIKey(apiKey)
                } else {
                    errorMessage = "API 密钥无效，请检查后重试"
                    showError = true
                }
                isLoading = false
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .blue.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
    }
}

struct DownloadsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                    .padding()
                
                Text("下载历史")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("您的下载历史将显示在这里")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("下载")
        }
    }
}