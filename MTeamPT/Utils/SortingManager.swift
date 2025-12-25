import Foundation

/// 排序选项
enum SortOption: String, CaseIterable {
    case recommended = "推荐排序"
    case newest = "最新发布"
    case sizeAsc = "大小升序"
    case sizeDesc = "大小降序"
    case seeders = "种子数"

    var icon: String {
        switch self {
        case .recommended: return "star.fill"
        case .newest: return "clock"
        case .sizeAsc: return "arrow.up"
        case .sizeDesc: return "arrow.down"
        case .seeders: return "arrow.up.circle.fill"
        }
    }
}

/// 排序管理器
class SortingManager {
    static let shared = SortingManager()

    private init() {}

    /// 对种子列表进行排序
    func sortTorrents(_ torrents: [Torrent], by option: SortOption) -> [Torrent] {
        switch option {
        case .recommended:
            return torrents.sorted { $0.recommendationScore > $1.recommendationScore }
        case .newest:
            return torrents.sorted {
                ($0.createdDateAsDate ?? .distantPast) > ($1.createdDateAsDate ?? .distantPast)
            }
        case .sizeAsc:
            return torrents.sorted { $0.sizeInBytes < $1.sizeInBytes }
        case .sizeDesc:
            return torrents.sorted { $0.sizeInBytes > $1.sizeInBytes }
        case .seeders:
            return torrents.sorted {
                (Int($0.status.seeders ?? "0") ?? 0) > (Int($1.status.seeders ?? "0") ?? 0)
            }
        }
    }
}
