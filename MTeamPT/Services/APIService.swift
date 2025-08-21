import Foundation
import Combine

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