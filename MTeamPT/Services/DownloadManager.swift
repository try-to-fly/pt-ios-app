import Foundation
import Combine

private class DownloadTaskContext {
    let torrentName: String
    let torrentId: String
    
    init(torrentName: String, torrentId: String) {
        self.torrentName = torrentName
        self.torrentId = torrentId
    }
}


class DownloadManager: NSObject {
    static let shared = DownloadManager()
    
    @Published var downloadProgress: [String: Double] = [:]
    @Published var downloads: [DownloadedTorrent] = []
    
    private var session: URLSession!
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var downloadCompletions: [String: (Result<DownloadedTorrent, Error>) -> Void] = [:]
    private var taskContexts: [String: DownloadTaskContext] = [:]
    
    override init() {
        super.init()
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        loadDownloadHistory()
    }
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var torrentsDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("Torrents")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    func downloadTorrentFile(from urlString: String, torrentName: String, torrentId: String, completion: @escaping (Result<DownloadedTorrent, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(DownloadError.invalidURL))
            return
        }
        
        print("[DownloadManager] 开始下载种子文件: \(urlString)")
        
        let taskId = UUID().uuidString
        
        // 保存任务的上下文信息
        let taskContext = DownloadTaskContext(torrentName: torrentName, torrentId: torrentId)
        downloadCompletions[taskId] = completion
        taskContexts[taskId] = taskContext
        
        let downloadTask = session.downloadTask(with: url)
        downloadTasks[taskId] = downloadTask
        
        downloadTask.taskDescription = taskId
        downloadTask.resume()
    }
    
    private func extractFileName(from response: URLResponse, fallbackName: String = "torrent") -> String {
        // 首先尝试从 Content-Disposition 响应头获取文件名
        if let httpResponse = response as? HTTPURLResponse,
           let contentDisposition = httpResponse.value(forHTTPHeaderField: "Content-Disposition") {
            
            // 解析 Content-Disposition 头，格式通常是：
            // attachment; filename="filename.torrent"
            // attachment; filename*=UTF-8''filename.torrent
            if let range = contentDisposition.range(of: "filename=") {
                var filename = String(contentDisposition[range.upperBound...])
                
                // 移除引号
                filename = filename.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                
                // 移除分号后的内容
                if let semicolonRange = filename.range(of: ";") {
                    filename = String(filename[..<semicolonRange.lowerBound])
                }
                
                if !filename.isEmpty {
                    print("[DownloadManager] 从 Content-Disposition 获取文件名: \(filename)")
                    return filename
                }
            }
            
            // 尝试解析 filename* 格式（UTF-8编码）
            if let range = contentDisposition.range(of: "filename\\*=UTF-8''", options: .regularExpression) {
                let encodedFilename = String(contentDisposition[range.upperBound...])
                if let decodedFilename = encodedFilename.removingPercentEncoding {
                    print("[DownloadManager] 从 filename* 获取文件名: \(decodedFilename)")
                    return decodedFilename
                }
            }
        }
        
        // 尝试从 URL 路径获取文件名
        if let filename = URL(string: response.url?.absoluteString ?? "")?.lastPathComponent,
           !filename.isEmpty && filename != "/" {
            print("[DownloadManager] 从 URL 路径获取文件名: \(filename)")
            return filename
        }
        
        // 使用默认文件名
        let timestamp = Int(Date().timeIntervalSince1970)
        let defaultName = "\(fallbackName)_\(timestamp).torrent"
        print("[DownloadManager] 使用默认文件名: \(defaultName)")
        return defaultName
    }
    
    private func saveDownloadHistory() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(downloads)
            UserDefaults.standard.set(data, forKey: "torrentDownloadHistory")
            
            print("[DownloadManager] 保存下载历史，共 \(downloads.count) 个文件")
        } catch {
            print("[DownloadManager] 保存下载历史失败: \(error)")
        }
    }
    
    private func loadDownloadHistory() {
        guard let data = UserDefaults.standard.data(forKey: "torrentDownloadHistory") else {
            downloads = []
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let loadedDownloads = try decoder.decode([DownloadedTorrent].self, from: data)
            // 过滤掉文件已被删除的记录
            downloads = loadedDownloads.filter { $0.isFileExists }
            
            print("[DownloadManager] 加载下载历史，共 \(downloads.count) 个文件")
        } catch {
            print("[DownloadManager] 加载下载历史失败: \(error)")
            downloads = []
        }
    }
    
    func deleteDownloadedFile(_ downloadedFile: DownloadedTorrent) {
        do {
            try FileManager.default.removeItem(at: downloadedFile.localURL)
            downloads.removeAll { $0.localURL == downloadedFile.localURL }
            saveDownloadHistory()
            print("[DownloadManager] 删除文件: \(downloadedFile.fileName)")
        } catch {
            print("[DownloadManager] 删除文件失败: \(error)")
        }
    }
    
    func shareFile(_ downloadedFile: DownloadedTorrent) -> [Any] {
        return [downloadedFile.localURL]
    }
}

// MARK: - URLSessionDownloadDelegate
extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let taskId = downloadTask.taskDescription,
              let completion = downloadCompletions[taskId],
              let taskContext = taskContexts[taskId] else {
            print("[DownloadManager] 未找到下载任务回调或上下文")
            return
        }
        
        // 清理任务引用
        downloadTasks.removeValue(forKey: taskId)
        downloadCompletions.removeValue(forKey: taskId)
        taskContexts.removeValue(forKey: taskId)
        
        do {
            // 获取文件名
            let fileName = extractFileName(from: downloadTask.response!)
            
            // 创建目标路径
            let destinationURL = torrentsDirectory.appendingPathComponent(fileName)
            
            // 如果文件已存在，添加时间戳避免冲突
            var finalURL = destinationURL
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                let timestamp = Int(Date().timeIntervalSince1970)
                let nameWithoutExtension = (fileName as NSString).deletingPathExtension
                let extension_ = (fileName as NSString).pathExtension
                let newFileName = "\(nameWithoutExtension)_\(timestamp).\(extension_)"
                finalURL = torrentsDirectory.appendingPathComponent(newFileName)
            }
            
            // 移动文件到目标位置
            try FileManager.default.moveItem(at: location, to: finalURL)
            
            let downloadedFile = DownloadedTorrent(
                fileName: finalURL.lastPathComponent,
                localURL: finalURL,
                downloadDate: Date(),
                originalURL: downloadTask.originalRequest?.url?.absoluteString ?? "",
                torrentName: taskContext.torrentName,
                torrentId: taskContext.torrentId
            )
            
            // 更新下载列表
            DispatchQueue.main.async {
                self.downloads.insert(downloadedFile, at: 0)
                self.saveDownloadHistory()
                completion(.success(downloadedFile))
            }
            
            print("[DownloadManager] 下载完成: \(downloadedFile.fileName)")
            
        } catch {
            print("[DownloadManager] 保存文件失败: \(error)")
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let taskId = downloadTask.taskDescription else { return }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        DispatchQueue.main.async {
            self.downloadProgress[taskId] = progress
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let taskId = task.taskDescription,
              let completion = downloadCompletions[taskId],
              let error = error else { return }
        
        // 清理任务引用
        downloadTasks.removeValue(forKey: taskId)
        downloadCompletions.removeValue(forKey: taskId)
        taskContexts.removeValue(forKey: taskId)
        
        DispatchQueue.main.async {
            self.downloadProgress.removeValue(forKey: taskId)
            completion(.failure(error))
        }
        
        print("[DownloadManager] 下载失败: \(error.localizedDescription)")
    }
}

enum DownloadError: LocalizedError {
    case invalidURL
    case fileNotFound
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的下载链接"
        case .fileNotFound:
            return "文件未找到"
        case .saveFailed:
            return "文件保存失败"
        }
    }
}