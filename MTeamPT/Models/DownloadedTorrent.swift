import Foundation

struct DownloadedTorrent: Codable, Identifiable {
    let id = UUID()
    let fileName: String
    let localURL: URL
    let downloadDate: Date
    let originalURL: String
    let torrentName: String
    let torrentId: String
    
    var fileSize: String {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: localURL.path)
            if let size = fileAttributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
        } catch {
            print("[DownloadedTorrent] 获取文件大小失败: \(error)")
        }
        return "未知大小"
    }
    
    var formattedDownloadDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: downloadDate)
    }
    
    var isFileExists: Bool {
        FileManager.default.fileExists(atPath: localURL.path)
    }
    
    init(fileName: String, localURL: URL, downloadDate: Date, originalURL: String, torrentName: String, torrentId: String) {
        self.fileName = fileName
        self.localURL = localURL
        self.downloadDate = downloadDate
        self.originalURL = originalURL
        self.torrentName = torrentName
        self.torrentId = torrentId
    }
}

extension DownloadedTorrent {
    static let example = DownloadedTorrent(
        fileName: "example.torrent",
        localURL: URL(fileURLWithPath: "/tmp/example.torrent"),
        downloadDate: Date(),
        originalURL: "https://example.com/download/123",
        torrentName: "示例电影.2024.4K.HDR.中字",
        torrentId: "123456"
    )
}