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
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SearchError.networkError("Invalid response")
            }
            
            if httpResponse.statusCode == 401 {
                throw SearchError.invalidAPIKey
            }
            
            guard httpResponse.statusCode == 200 else {
                throw SearchError.networkError("HTTP \(httpResponse.statusCode)")
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
            throw error
        } catch {
            if error is DecodingError {
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
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SearchError.networkError("Invalid response")
            }
            
            if httpResponse.statusCode == 401 {
                throw SearchError.invalidAPIKey
            }
            
            guard httpResponse.statusCode == 200 else {
                throw SearchError.networkError("HTTP \(httpResponse.statusCode)")
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
            throw error
        } catch {
            if error is DecodingError {
                throw SearchError.decodingError
            }
            throw SearchError.networkError(error.localizedDescription)
        }
    }
    
    func validateAPIKey(_ key: String) async -> Bool {
        let tempKey = apiKey
        KeychainManager.shared.saveAPIKey(key)
        
        do {
            let params = SearchParams(keyword: "test", pageSize: 1)
            _ = try await searchTorrents(params: params)
            return true
        } catch {
            if tempKey != nil {
                KeychainManager.shared.saveAPIKey(tempKey!)
            } else {
                KeychainManager.shared.deleteAPIKey()
            }
            return false
        }
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