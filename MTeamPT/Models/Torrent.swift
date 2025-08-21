import Foundation

struct Torrent: Identifiable, Codable, Hashable {
    let id: String
    let createdDate: String
    let lastModifiedDate: String
    let name: String
    let smallDescr: String
    let imdb: String?
    let imdbRating: String?
    let douban: String?
    let doubanRating: String?
    let dmmCode: String?
    let author: String?
    let category: String
    let source: String?
    let medium: String?
    let standard: String
    let videoCodec: String
    let audioCodec: String
    let team: String?
    let processing: String?
    let countries: [String]
    let numfiles: String
    let size: String
    let labels: String
    let labelsNew: [String]
    let msUp: String
    let anonymous: Bool
    let infoHash: String?
    let status: TorrentStatus
    let dmmInfo: String?
    let editedBy: String?
    let editDate: String?
    let collection: Bool
    let inRss: Bool
    let canVote: Bool
    let imageList: [String]
    let resetBox: String?
    
    var formattedSize: String {
        guard let bytes = Double(size) else { return "未知" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    var displayRating: String? {
        if let imdbRating = imdbRating, !imdbRating.isEmpty {
            return "IMDB: \(imdbRating)"
        } else if let doubanRating = doubanRating, !doubanRating.isEmpty {
            return "豆瓣: \(doubanRating)"
        }
        return nil
    }
    
    var healthStatus: HealthStatus {
        guard let seeders = Int(status.seeders),
              let _ = Int(status.leechers) else {
            return .unknown
        }
        
        if seeders >= 10 {
            return .excellent
        } else if seeders >= 5 {
            return .good
        } else if seeders >= 1 {
            return .fair
        } else {
            return .poor
        }
    }
    
    var discountType: DiscountType {
        DiscountType(rawValue: status.discount) ?? .none
    }
    
    var hasDiscount: Bool {
        discountType != .none
    }
}

struct TorrentStatus: Codable, Hashable {
    let id: String
    let createdDate: String
    let lastModifiedDate: String
    let pickType: String
    let toppingLevel: String
    let toppingEndTime: String?
    let discount: String
    let discountEndTime: String?
    let timesCompleted: String
    let comments: String
    let lastAction: String
    let lastSeederAction: String
    let views: String
    let hits: String
    let support: String
    let oppose: String
    let status: String
    let seeders: String
    let leechers: String
    let banned: Bool
    let visible: Bool
    let promotionRule: String?
    let mallSingleFree: String?
}

enum HealthStatus {
    case excellent
    case good
    case fair
    case poor
    case unknown
    
    var color: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .fair:
            return "yellow"
        case .poor:
            return "red"
        case .unknown:
            return "gray"
        }
    }
    
    var description: String {
        switch self {
        case .excellent:
            return "极佳"
        case .good:
            return "良好"
        case .fair:
            return "一般"
        case .poor:
            return "较差"
        case .unknown:
            return "未知"
        }
    }
}

enum DiscountType: String {
    case none = ""
    case free = "FREE"
    case percent50 = "PERCENT_50"
    case percent30 = "PERCENT_30"
    case percent70 = "PERCENT_70"
    case twoXFree = "_2X_FREE"
    case twoX = "_2X"
    case twoXPercent50 = "_2X_PERCENT_50"
    
    var displayText: String {
        switch self {
        case .none:
            return ""
        case .free:
            return "免费"
        case .percent50:
            return "50%"
        case .percent30:
            return "30%"
        case .percent70:
            return "70%"
        case .twoXFree:
            return "2X免费"
        case .twoX:
            return "2X"
        case .twoXPercent50:
            return "2X 50%"
        }
    }
    
    var badgeColor: String {
        switch self {
        case .none:
            return "gray"
        case .free, .twoXFree:
            return "green"
        case .percent50, .percent30, .percent70:
            return "blue"
        case .twoX, .twoXPercent50:
            return "orange"
        }
    }
}

enum TorrentCategory: String, CaseIterable {
    case all = "normal"
    case tvshow = "tvshow"
    case movie = "movie"
    
    var displayName: String {
        switch self {
        case .all:
            return "全部"
        case .tvshow:
            return "电视"
        case .movie:
            return "电影"
        }
    }
    
    var iconName: String {
        switch self {
        case .all:
            return "square.grid.2x2"
        case .tvshow:
            return "tv"
        case .movie:
            return "film"
        }
    }
}