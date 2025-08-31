import SwiftUI
import Combine
import UIKit

@MainActor
class DownloadsViewModel: ObservableObject {
    @Published var downloads: [DownloadedTorrent] = []
    @Published var showDeleteConfirmation = false
    
    private let downloadManager = DownloadManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var downloadToDelete: DownloadedTorrent?
    
    init() {
        setupSubscriptions()
        refreshDownloads()
    }
    
    private func setupSubscriptions() {
        // 监听下载管理器的下载列表变化
        downloadManager.$downloads
            .receive(on: DispatchQueue.main)
            .assign(to: \.downloads, on: self)
            .store(in: &cancellables)
    }
    
    func refreshDownloads() {
        downloads = downloadManager.downloads
    }
    
    func requestDelete(_ download: DownloadedTorrent) {
        downloadToDelete = download
        showDeleteConfirmation = true
    }
    
    func confirmDelete() {
        guard let download = downloadToDelete else { return }
        
        downloadManager.deleteDownloadedFile(download)
        downloadToDelete = nil
        
        HapticManager.shared.notification(.success)
    }
    
    func shareFile(_ download: DownloadedTorrent) -> [Any] {
        return downloadManager.shareFile(download)
    }
    
    func clearAllDownloads() {
        let downloads = self.downloads
        
        for download in downloads {
            downloadManager.deleteDownloadedFile(download)
        }
        
        HapticManager.shared.notification(.success)
    }
}

struct DownloadsView: View {
    @StateObject private var viewModel = DownloadsViewModel()
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.downloads.isEmpty {
                    emptyStateView
                } else {
                    downloadList
                }
            }
            .navigationTitle("下载列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.clearAllDownloads()
                        } label: {
                            Label("清空列表", systemImage: "trash")
                        }
                        
                        Button {
                            viewModel.refreshDownloads()
                        } label: {
                            Label("刷新", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .alert("确认删除", isPresented: $viewModel.showDeleteConfirmation) {
            Button("删除", role: .destructive) {
                viewModel.confirmDelete()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除这个种子文件吗？")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("暂无下载")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("下载的种子文件将显示在这里")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var downloadList: some View {
        List {
            ForEach(viewModel.downloads, id: \.id) { download in
                DownloadRowView(
                    download: download,
                    onShare: { download in
                        shareItems = viewModel.shareFile(download)
                        showingShareSheet = true
                    },
                    onDelete: { download in
                        viewModel.requestDelete(download)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color(.systemGroupedBackground))
            }
        }
        .listStyle(PlainListStyle())
        .background(Color(.systemGroupedBackground))
    }
}

struct DownloadRowView: View {
    let download: DownloadedTorrent
    let onShare: (DownloadedTorrent) -> Void
    let onDelete: (DownloadedTorrent) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 文件图标
                Image(systemName: "doc.badge.arrow.down")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                    )
                
                // 文件信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(download.torrentName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(download.fileName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        Text(download.fileSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(download.formattedDownloadDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .contextMenu {
                Button {
                    onShare(download)
                } label: {
                    Label("分享", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive) {
                    onDelete(download)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }
}

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
                    Text("欢迎使用 Cat")
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
            let result = await APIService.shared.validateAPIKey(apiKey)
            
            await MainActor.run {
                if result.isValid {
                    appState.saveAPIKey(apiKey)
                } else {
                    errorMessage = result.errorMessage ?? "API 密钥验证失败"
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

