import Foundation
import SwiftUI

@MainActor
class TorrentDetailViewModel: ObservableObject {
    @Published var torrent: Torrent
    @Published var isLoadingDownload = false
    @Published var downloadURL: String?
    @Published var showDownloadOptions = false
    @Published var showShareSheet = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isFavorite = false
    
    private let apiService = APIService.shared
    
    init(torrent: Torrent) {
        self.torrent = torrent
        checkFavoriteStatus()
    }
    
    var formattedLabels: [(String, Color)] {
        torrent.labelsNew.map { label in
            let color: Color = {
                switch label.lowercased() {
                case let l where l.contains("4k"):
                    return .purple
                case let l where l.contains("hdr"):
                    return .orange
                case let l where l.contains("中字"):
                    return .blue
                case let l where l.contains("中配"):
                    return .green
                case let l where l.contains("dolby"):
                    return .red
                default:
                    return .gray
                }
            }()
            return (label, color)
        }
    }
    
    var seedersColor: Color {
        switch torrent.healthStatus {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .yellow
        case .poor:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    func getDownloadLink() {
        isLoadingDownload = true
        errorMessage = nil
        
        Task {
            do {
                let url = try await apiService.getTorrentDownloadURL(torrentId: torrent.id)
                self.downloadURL = url
                self.showDownloadOptions = true
                
                saveToHistory()
                
            } catch {
                self.handleError(error)
            }
            
            self.isLoadingDownload = false
        }
    }
    
    func openInExternalApp() {
        guard let urlString = downloadURL,
              let url = URL(string: urlString) else { return }
        
        UIApplication.shared.open(url)
    }
    
    func copyDownloadLink() {
        guard let url = downloadURL else { return }
        
        UIPasteboard.general.string = url
        
        HapticManager.shared.impact(.light)
    }
    
    func shareTorrent() {
        showShareSheet = true
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
        
        if isFavorite {
            saveFavorite()
        } else {
            removeFavorite()
        }
        
        HapticManager.shared.impact(.light)
    }
    
    private func checkFavoriteStatus() {
        let favorites = UserDefaults.standard.stringArray(forKey: "favorites") ?? []
        isFavorite = favorites.contains(torrent.id)
    }
    
    private func saveFavorite() {
        var favorites = UserDefaults.standard.stringArray(forKey: "favorites") ?? []
        if !favorites.contains(torrent.id) {
            favorites.append(torrent.id)
            UserDefaults.standard.set(favorites, forKey: "favorites")
        }
    }
    
    private func removeFavorite() {
        var favorites = UserDefaults.standard.stringArray(forKey: "favorites") ?? []
        favorites.removeAll { $0 == torrent.id }
        UserDefaults.standard.set(favorites, forKey: "favorites")
    }
    
    private func saveToHistory() {
        var history = UserDefaults.standard.stringArray(forKey: "downloadHistory") ?? []
        
        history.removeAll { $0 == torrent.id }
        history.insert(torrent.id, at: 0)
        
        if history.count > 100 {
            history = Array(history.prefix(100))
        }
        
        UserDefaults.standard.set(history, forKey: "downloadHistory")
    }
    
    private func handleError(_ error: Error) {
        if let searchError = error as? SearchError {
            errorMessage = searchError.localizedDescription
        } else {
            errorMessage = "获取下载链接失败，请重试"
        }
        showError = true
    }
}

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}