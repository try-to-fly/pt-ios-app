import Foundation
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
    
    func openSharePanel(for download: DownloadedTorrent) {
        let activityVC = UIActivityViewController(
            activityItems: [download.localURL],
            applicationActivities: nil
        )
        
        // 获取当前最顶层的 view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            var topVC = rootVC
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            }
            
            topVC.present(activityVC, animated: true)
            HapticManager.shared.impact(.light)
        }
    }
    
    func clearAllDownloads() {
        let downloads = self.downloads
        
        for download in downloads {
            downloadManager.deleteDownloadedFile(download)
        }
        
        HapticManager.shared.notification(.success)
    }
    
    var totalDownloads: Int {
        downloads.count
    }
    
    var totalSize: String {
        let totalBytes = downloads.compactMap { download in
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: download.localURL.path)
                return attributes[.size] as? Int64 ?? 0
            } catch {
                return nil
            }
        }.reduce(0, +)
        
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
}