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

class DownloadManager: NSObject, ObservableObject {
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
    
    /// 修复 Mojibake（文字化け）问题
    /// 当 UTF-8 编码的文本被错误地解释为 ISO-8859-1 时会产生乱码
    /// 例如："哪吒" 会变成 "åªå"
    private func fixMojibake(_ text: String) -> String {
        // 将字符串作为 ISO-8859-1 字节重新解释为 UTF-8
        var bytes = [UInt8]()
        for scalar in text.unicodeScalars {
            if scalar.value <= 0xFF {
                bytes.append(UInt8(scalar.value))
            } else {
                // 如果字符超出单字节范围，说明不是 Mojibake，返回原文本
                return text
            }
        }
        
        // 尝试将字节数组解释为 UTF-8
        if let fixed = String(bytes: bytes, encoding: .utf8) {
            // 简单验证：检查是否包含中文字符
            let chineseCharacterRange = NSRange(location: 0x4E00, length: 0x9FFF - 0x4E00)
            var containsChinese = false
            for scalar in fixed.unicodeScalars {
                if NSLocationInRange(Int(scalar.value), chineseCharacterRange) {
                    containsChinese = true
                    break
                }
            }
            
            if containsChinese {
                return fixed
            }
            
            // 即使不包含中文，如果修复后的文本没有控制字符，也使用修复后的
            let controlCharPattern = "[\u{0000}-\u{001F}\u{007F}]"
            if fixed.range(of: controlCharPattern, options: .regularExpression) == nil {
                return fixed
            }
        }
        
        // 如果修复失败，返回原文本
        return text
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
                
                // 尝试修复 Mojibake（文字化け）问题
                // 当 UTF-8 文本被错误地解释为 ISO-8859-1 时会出现这种乱码
                filename = fixMojibake(filename)
                
                // 对文件名进行 URL 解码，处理中文等特殊字符
                if let decodedFilename = filename.removingPercentEncoding {
                    filename = decodedFilename
                }
                
                if !filename.isEmpty {
                    print("[APIService] 从 Content-Disposition 获取文件名: \(filename)")
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

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://api.m-team.cc"
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        
        self.session = URLSession(configuration: configuration)
    }
    
    private var apiKey: String? {
        KeychainManager.shared.getAPIKey()
    }
    
    func searchTorrents(params: SearchParams) async throws -> SearchResult {
        guard let apiKey = apiKey else {
            throw SearchError.invalidAPIKey
        }
        
        let url = URL(string: "\(baseURL)/api/torrent/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(params)
        
        // 添加请求体日志
        if let requestBody = request.httpBody,
           let requestString = String(data: requestBody, encoding: .utf8) {
            print("[APIService] 请求体: \(requestString)")
        }
        
        do {
            print("[APIService] 发送搜索请求到: \(url)")
            print("[APIService] API Key: \(String(apiKey.prefix(8)))...")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[APIService] 无效的响应格式")
                throw SearchError.networkError("无效的响应格式")
            }
            
            print("[APIService] HTTP 状态码: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 401 {
                print("[APIService] API 密钥认证失败")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[APIService] 响应内容: \(responseString)")
                }
                throw SearchError.invalidAPIKey
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMsg = "HTTP \(httpResponse.statusCode)"
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[APIService] 错误响应: \(responseString)")
                }
                throw SearchError.networkError(errorMsg)
            }
            
            // 添加响应体日志
            if let responseString = String(data: data, encoding: .utf8) {
                print("[APIService] 响应体: \(responseString)")
            }
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(APIResponse.self, from: data)
            
            if !apiResponse.isSuccess {
                throw SearchError.apiError(apiResponse.errorMessage ?? "Unknown error")
            }
            
            guard let pageData = apiResponse.data else {
                return SearchResult.empty
            }
            
            return SearchResult(from: pageData)
            
        } catch let error as SearchError {
            print("[APIService] 搜索错误: \(error.localizedDescription)")
            throw error
        } catch {
            print("[APIService] 未预期错误: \(error)")
            if error is DecodingError {
                print("[APIService] JSON 解析失败")
                throw SearchError.decodingError
            }
            throw SearchError.networkError(error.localizedDescription)
        }
    }
    
    func getTorrentDownloadURL(torrentId: String) async throws -> String {
        guard let apiKey = apiKey else {
            throw SearchError.invalidAPIKey
        }
        
        let url = URL(string: "\(baseURL)/api/torrent/genDlToken")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "id=\(torrentId)"
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            print("[APIService] 发送下载链接请求到: \(url)")
            print("[APIService] API Key: \(String(apiKey.prefix(8)))...")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[APIService] 无效的响应格式")
                throw SearchError.networkError("无效的响应格式")
            }
            
            print("[APIService] HTTP 状态码: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 401 {
                print("[APIService] API 密钥认证失败")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[APIService] 响应内容: \(responseString)")
                }
                throw SearchError.invalidAPIKey
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMsg = "HTTP \(httpResponse.statusCode)"
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[APIService] 错误响应: \(responseString)")
                }
                throw SearchError.networkError(errorMsg)
            }
            
            let decoder = JSONDecoder()
            let dlResponse = try decoder.decode(GenDlTokenResponse.self, from: data)
            
            if !dlResponse.isSuccess {
                throw SearchError.apiError(dlResponse.message)
            }
            
            guard let downloadURL = dlResponse.downloadURL else {
                throw SearchError.apiError("No download URL returned")
            }
            
            return downloadURL
            
        } catch let error as SearchError {
            print("[APIService] 下载链接获取错误: \(error.localizedDescription)")
            throw error
        } catch {
            print("[APIService] 下载链接未预期错误: \(error)")
            if error is DecodingError {
                print("[APIService] JSON 解析失败")
                throw SearchError.decodingError
            }
            throw SearchError.networkError(error.localizedDescription)
        }
    }
    
    func validateAPIKey(_ key: String) async -> (isValid: Bool, errorMessage: String?) {
        // 保存当前密钥作为备份
        let tempKey = apiKey
        
        // 清理并验证密钥格式
        let cleanedKey = cleanAPIKey(key)
        guard !cleanedKey.isEmpty else {
            return (false, "API 密钥不能为空")
        }
        
        guard cleanedKey.count >= 32 else {
            return (false, "API 密钥格式错误，长度不足")
        }
        
        // 临时保存新密钥进行验证
        KeychainManager.shared.saveAPIKey(cleanedKey)
        
        do {
            let params = SearchParams(keyword: "test", pageSize: 1)
            _ = try await searchTorrents(params: params)
            return (true, nil)
        } catch let error as SearchError {
            // 恢复原密钥
            if let tempKey = tempKey {
                KeychainManager.shared.saveAPIKey(tempKey)
            } else {
                KeychainManager.shared.deleteAPIKey()
            }
            
            let errorMessage: String
            switch error {
            case .invalidAPIKey:
                errorMessage = "API 密钥无效或已过期"
            case .networkError(let message):
                errorMessage = "网络连接失败: \(message)"
            case .apiError(let message):
                errorMessage = "服务器错误: \(message)"
            case .decodingError:
                errorMessage = "服务器响应格式错误"
            case .unknown:
                errorMessage = "未知错误"
            }
            
            print("[APIService] API 密钥验证失败: \(errorMessage)")
            return (false, errorMessage)
        } catch {
            // 恢复原密钥
            if let tempKey = tempKey {
                KeychainManager.shared.saveAPIKey(tempKey)
            } else {
                KeychainManager.shared.deleteAPIKey()
            }
            
            let errorMessage = "验证失败: \(error.localizedDescription)"
            print("[APIService] API 密钥验证出现异常: \(errorMessage)")
            return (false, errorMessage)
        }
    }
    
    private func cleanAPIKey(_ key: String) -> String {
        // 移除首尾空格和换行符
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        // 移除中间的空格和换行符
        return trimmed.replacingOccurrences(of: "\\\\s+", with: "", options: .regularExpression)
    }
    
    func downloadImage(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
}

extension APIService {
    func searchPublisher(params: SearchParams) -> AnyPublisher<SearchResult, SearchError> {
        Future { promise in
            Task {
                do {
                    let result = try await self.searchTorrents(params: params)
                    promise(.success(result))
                } catch let error as SearchError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.unknown))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}