import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showAPIKeyEditor = false
    @State private var showLogoutAlert = false
    @State private var showClearCacheAlert = false
    @State private var cacheSize = "0 MB"
    
    var body: some View {
        NavigationView {
            List {
                accountSection
                
                appearanceSection
                
                cacheSection
                
                aboutSection
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showAPIKeyEditor) {
                APIKeyEditorView()
                    .environmentObject(appState)
            }
            .alert("确认登出", isPresented: $showLogoutAlert) {
                Button("取消", role: .cancel) { }
                Button("登出", role: .destructive) {
                    appState.logout()
                }
            } message: {
                Text("登出后需要重新输入 API 密钥才能使用应用")
            }
            .alert("清除缓存", isPresented: $showClearCacheAlert) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    CacheManager.shared.clearCache()
                    updateCacheSize()
                }
            } message: {
                Text("这将清除所有缓存的搜索结果和图片")
            }
            .onAppear {
                updateCacheSize()
            }
        }
    }
    
    private var accountSection: some View {
        Section {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("API 密钥")
                        .font(.body)
                    Text(maskedAPIKey)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("编辑") {
                    showAPIKeyEditor = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.vertical, 4)
            
            Button(action: { showLogoutAlert = true }) {
                HStack {
                    Image(systemName: "arrow.right.square")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("登出")
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("账户")
        }
    }
    
    private var appearanceSection: some View {
        Section {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.indigo)
                    .frame(width: 24)
                
                Text("外观")
                
                Spacer()
                
                Picker("外观", selection: $themeManager.colorScheme) {
                    Text("跟随系统").tag(nil as ColorScheme?)
                    Text("浅色").tag(ColorScheme.light)
                    Text("深色").tag(ColorScheme.dark)
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: themeManager.colorScheme) { newValue in
                    themeManager.setColorScheme(newValue)
                }
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: ThemeCustomizationView()) {
                HStack {
                    Image(systemName: "paintbrush.fill")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    Text("主题定制")
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("外观设置")
        }
    }
    
    private var cacheSection: some View {
        Section {
            HStack {
                Image(systemName: "internaldrive")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("缓存大小")
                        .font(.body)
                    Text(cacheSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("清除") {
                    showClearCacheAlert = true
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding(.vertical, 4)
        } header: {
            Text("存储")
        } footer: {
            Text("清除缓存可以释放存储空间，但会影响应用加载速度")
        }
    }
    
    private var aboutSection: some View {
        Section {
            NavigationLink(destination: AboutView()) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("关于应用")
                }
                .padding(.vertical, 4)
            }
            
            Link(destination: URL(string: "https://github.com/mteam/ios-app")!) {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Text("开源地址")
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Button(action: {
                guard let url = URL(string: "mailto:support@mteam.app") else { return }
                UIApplication.shared.open(url)
            }) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("联系我们")
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("支持")
        }
    }
    
    private var maskedAPIKey: String {
        let key = appState.apiKey
        guard key.count > 8 else { return "••••••••" }
        let start = key.prefix(4)
        let end = key.suffix(4)
        return "\(start)••••\(end)"
    }
    
    private func updateCacheSize() {
        DispatchQueue.global(qos: .background).async {
            let size = calculateCacheSize()
            DispatchQueue.main.async {
                cacheSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .binary)
            }
        }
    }
    
    private func calculateCacheSize() -> Int64 {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MTeamPT", isDirectory: true)
        
        var totalSize: Int64 = 0
        
        if let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                   let size = attributes[.size] as? Int64 {
                    totalSize += size
                }
            }
        }
        
        return totalSize
    }
}

struct APIKeyEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var newAPIKey = ""
    @State private var isValidating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("更新 API 密钥")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("输入新的 API 密钥来更新您的账户设置")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("提示：")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        Text("• API 密钥应为 32 位以上的字符串\n• 请确保复制完整的密钥，避免多余的空格\n• 如果仍然无效，请检查账户状态或联系管理员")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API 密钥")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("输入新的 API 密钥", text: $newAPIKey)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: validateAndSave) {
                        if isValidating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("保存")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(newAPIKey.isEmpty || isValidating)
                    
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationBarHidden(true)
            .onAppear {
                newAPIKey = appState.apiKey
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func validateAndSave() {
        isValidating = true
        
        Task {
            let result = await APIService.shared.validateAPIKey(newAPIKey)
            
            await MainActor.run {
                if result.isValid {
                    appState.saveAPIKey(newAPIKey)
                    dismiss()
                } else {
                    errorMessage = result.errorMessage ?? "API 密钥验证失败"
                    showError = true
                }
                isValidating = false
            }
        }
    }
}

struct ThemeCustomizationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let accentColors: [Color] = [
        .blue, .purple, .pink, .red, .orange, .yellow, .green, .indigo
    ]
    
    var body: some View {
        List {
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                    ForEach(accentColors, id: \.self) { color in
                        Button(action: {
                            themeManager.accentColor = color
                            HapticManager.shared.impact(.light)
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: themeManager.accentColor == color ? 3 : 0)
                                )
                                .scaleEffect(themeManager.accentColor == color ? 1.1 : 1)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: themeManager.accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("主题色")
            } footer: {
                Text("选择您喜欢的主题色彩")
            }
        }
        .navigationTitle("主题定制")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("M-Team PT")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("版本 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("关于应用")
                        .font(.headline)
                    
                    Text("M-Team PT 是一款专为 M-Team 用户设计的移动端应用，提供便捷的种子搜索和下载功能。")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("主要功能")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "magnifyingglass", text: "种子搜索和筛选")
                        FeatureRow(icon: "arrow.down.circle", text: "一键获取下载链接")
                        FeatureRow(icon: "heart", text: "收藏和历史记录")
                        FeatureRow(icon: "moon", text: "深色模式支持")
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}