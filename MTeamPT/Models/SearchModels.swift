import Foundation

struct SearchParams: Codable {
    let mode: String
    let visible: Int
    let keyword: String
    let categories: [String]
    let pageNumber: Int
    let pageSize: Int
    
    init(keyword: String, category: TorrentCategory = .all, pageNumber: Int = 1, pageSize: Int = 20) {
        self.mode = category.rawValue
        self.visible = 1
        self.keyword = keyword
        self.categories = []
        self.pageNumber = pageNumber
        self.pageSize = min(pageSize, 100)
    }
}

struct PageData: Codable {
    let pageNumber: String
    let pageSize: String
    let total: String
    let totalPages: String
    let data: [Torrent]
    
    var currentPage: Int {
        Int(pageNumber) ?? 1
    }
    
    var totalItems: Int {
        Int(total) ?? 0
    }
    
    var totalPageCount: Int {
        Int(totalPages) ?? 0
    }
    
    var hasMorePages: Bool {
        currentPage < totalPageCount
    }
}

struct APIResponse: Codable {
    let code: String
    let message: String
    let data: PageData?
    
    var isSuccess: Bool {
        code == "0"
    }
    
    var errorMessage: String? {
        if isSuccess {
            return nil
        }
        return message.isEmpty ? "未知错误" : message
    }
}

struct GenDlTokenResponse: Codable {
    let code: String
    let message: String
    let data: String?
    
    var isSuccess: Bool {
        code == "0"
    }
    
    var downloadURL: String? {
        isSuccess ? data : nil
    }
}

struct SearchResult {
    let torrents: [Torrent]
    let hasMore: Bool
    let totalCount: Int
    let currentPage: Int
    let totalPages: Int
    
    init(from pageData: PageData) {
        self.torrents = pageData.data
        self.hasMore = pageData.hasMorePages
        self.totalCount = pageData.totalItems
        self.currentPage = pageData.currentPage
        self.totalPages = pageData.totalPageCount
    }
    
    static var empty: SearchResult {
        SearchResult(
            torrents: [],
            hasMore: false,
            totalCount: 0,
            currentPage: 1,
            totalPages: 0
        )
    }
    
    init(torrents: [Torrent], hasMore: Bool, totalCount: Int, currentPage: Int, totalPages: Int) {
        self.torrents = torrents
        self.hasMore = hasMore
        self.totalCount = totalCount
        self.currentPage = currentPage
        self.totalPages = totalPages
    }
}

enum SearchError: LocalizedError {
    case invalidAPIKey
    case networkError(String)
    case apiError(String)
    case decodingError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "API密钥无效或已过期"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .apiError(let message):
            return "API错误: \(message)"
        case .decodingError:
            return "数据解析失败"
        case .unknown:
            return "未知错误"
        }
    }
}