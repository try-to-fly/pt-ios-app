import Foundation
import SwiftUI

struct DownloadedTorrent: Codable, Identifiable {
    let id: UUID
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
        self.id = UUID()
        self.fileName = fileName
        self.localURL = localURL
        self.downloadDate = downloadDate
        self.originalURL = originalURL
        self.torrentName = torrentName
        self.torrentId = torrentId
    }
}

struct Torrent: Identifiable, Codable, Hashable {
    let id: String
    let createdDate: String
    let lastModifiedDate: String
    let name: String
    let smallDescr: String?
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
    let videoCodec: String?
    let audioCodec: String?
    let team: String?
    let processing: String?
    let countries: [String]
    let numfiles: String
    let size: String
    let labels: String?
    let labelsNew: [String]
    let msUp: String?
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
        guard let seedersStr = status.seeders,
              let leechersStr = status.leechers,
              let seeders = Int(seedersStr),
              let _ = Int(leechersStr) else {
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
    
    var displayTitle: String {
        if let smallDescr = smallDescr, !smallDescr.isEmpty {
            return smallDescr
        }
        return name
    }
    
    // 将createdDate字符串转换为Date对象
    var createdDateAsDate: Date? {
        // API返回的日期格式通常是 "yyyy-MM-dd HH:mm:ss" 或 ISO 8601
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // 尝试多种日期格式
        let dateFormats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        ]
        
        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: createdDate) {
                return date
            }
        }
        
        // 如果是时间戳（Unix timestamp）
        if let timestamp = Double(createdDate) {
            return Date(timeIntervalSince1970: timestamp)
        }
        
        return nil
    }
    
    // 获取相对时间显示
    var relativeCreatedTime: String {
        guard let date = createdDateAsDate else {
            return "未知时间"
        }
        return date.relativeTimeDisplay()
    }
    
    // 获取时间显示的颜色
    var createdTimeColor: Color {
        guard let date = createdDateAsDate else {
            return .secondary
        }
        return date.relativeTimeColor()
    }
}

// PromotionRule 可以是字符串或对象，使用枚举来处理
enum PromotionRule: Codable, Hashable {
    case string(String)
    case object([String: AnyCodable])
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // 首先尝试解码为字符串
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }
        
        // 尝试解码为字典
        if let dictValue = try? container.decode([String: AnyCodable].self) {
            self = .object(dictValue)
            return
        }
        
        // 如果是 null
        if container.decodeNil() {
            self = .null
            return
        }
        
        // 如果都不是，抛出错误
        throw DecodingError.typeMismatch(
            PromotionRule.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected String, Dictionary or null"
            )
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
    
    // 获取字符串值（如果是字符串类型）
    var stringValue: String? {
        switch self {
        case .string(let value):
            return value
        case .object, .null:
            return nil
        }
    }
}

// AnyCodable 用于处理未知类型的值
struct AnyCodable: Codable, Hashable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value
        } else if let value = try? container.decode([AnyCodable].self) {
            self.value = value
        } else if container.decodeNil() {
            self.value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode value"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let value as Bool:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case let value as String:
            try container.encode(value)
        case let value as [String: AnyCodable]:
            try container.encode(value)
        case let value as [AnyCodable]:
            try container.encode(value)
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Cannot encode value"
                )
            )
        }
    }
    
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // 简单的相等性比较
        switch (lhs.value, rhs.value) {
        case (let l as Bool, let r as Bool):
            return l == r
        case (let l as Int, let r as Int):
            return l == r
        case (let l as Double, let r as Double):
            return l == r
        case (let l as String, let r as String):
            return l == r
        case (is NSNull, is NSNull):
            return true
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch value {
        case let value as Bool:
            hasher.combine(value)
        case let value as Int:
            hasher.combine(value)
        case let value as Double:
            hasher.combine(value)
        case let value as String:
            hasher.combine(value)
        case is NSNull:
            hasher.combine(0)
        default:
            hasher.combine(0)
        }
    }
}

struct TorrentStatus: Codable, Hashable {
    let id: String
    let createdDate: String
    let lastModifiedDate: String
    let pickType: String?
    let toppingLevel: String?
    let toppingEndTime: String?
    let discount: String
    let discountEndTime: String?
    let timesCompleted: String?
    let comments: String?
    let lastAction: String?
    let lastSeederAction: String?
    let views: String?
    let hits: String?
    let support: String?
    let oppose: String?
    let status: String?
    let seeders: String?
    let leechers: String?
    let banned: Bool
    let visible: Bool
    let promotionRule: PromotionRule?
    let mallSingleFree: String?
    
    // 自定义解码以处理 promotionRule 的特殊情况
    enum CodingKeys: String, CodingKey {
        case id, createdDate, lastModifiedDate, pickType, toppingLevel
        case toppingEndTime, discount, discountEndTime, timesCompleted
        case comments, lastAction, lastSeederAction, views, hits
        case support, oppose, status, seeders, leechers
        case banned, visible, promotionRule, mallSingleFree
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        createdDate = try container.decode(String.self, forKey: .createdDate)
        lastModifiedDate = try container.decode(String.self, forKey: .lastModifiedDate)
        pickType = try container.decodeIfPresent(String.self, forKey: .pickType)
        toppingLevel = try container.decodeIfPresent(String.self, forKey: .toppingLevel)
        toppingEndTime = try container.decodeIfPresent(String.self, forKey: .toppingEndTime)
        discount = try container.decode(String.self, forKey: .discount)
        discountEndTime = try container.decodeIfPresent(String.self, forKey: .discountEndTime)
        timesCompleted = try container.decodeIfPresent(String.self, forKey: .timesCompleted)
        comments = try container.decodeIfPresent(String.self, forKey: .comments)
        lastAction = try container.decodeIfPresent(String.self, forKey: .lastAction)
        lastSeederAction = try container.decodeIfPresent(String.self, forKey: .lastSeederAction)
        views = try container.decodeIfPresent(String.self, forKey: .views)
        hits = try container.decodeIfPresent(String.self, forKey: .hits)
        support = try container.decodeIfPresent(String.self, forKey: .support)
        oppose = try container.decodeIfPresent(String.self, forKey: .oppose)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        seeders = try container.decodeIfPresent(String.self, forKey: .seeders)
        leechers = try container.decodeIfPresent(String.self, forKey: .leechers)
        banned = try container.decode(Bool.self, forKey: .banned)
        visible = try container.decode(Bool.self, forKey: .visible)
        
        // 特殊处理 promotionRule
        if container.contains(.promotionRule) {
            promotionRule = try container.decodeIfPresent(PromotionRule.self, forKey: .promotionRule)
        } else {
            promotionRule = nil
        }
        
        mallSingleFree = try container.decodeIfPresent(String.self, forKey: .mallSingleFree)
    }
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

enum TorrentCategory: String, CaseIterable, Codable {
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