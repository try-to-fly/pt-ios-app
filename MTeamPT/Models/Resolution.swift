import Foundation

/// 视频分辨率枚举
enum Resolution: Int, Comparable, CaseIterable {
    case unknown = 0
    case sd = 1        // 标清
    case p720 = 2      // 720P
    case p1080 = 3     // 1080P
    case p2k = 4       // 2K
    case p4k = 5       // 4K

    /// 排序优先级：1080P > 2K > 720P > 4K > SD > unknown
    var sortPriority: Int {
        switch self {
        case .p1080: return 100
        case .p2k: return 80
        case .p720: return 60
        case .p4k: return 20  // 4K 文件通常过大，优先级较低
        case .sd: return 10
        case .unknown: return 0
        }
    }

    var displayName: String {
        switch self {
        case .unknown: return "未知"
        case .sd: return "标清"
        case .p720: return "720P"
        case .p1080: return "1080P"
        case .p2k: return "2K"
        case .p4k: return "4K"
        }
    }

    static func < (lhs: Resolution, rhs: Resolution) -> Bool {
        lhs.sortPriority < rhs.sortPriority
    }

    /// 从标签字符串数组中提取分辨率
    static func fromLabels(_ labels: [String]) -> Resolution {
        let labelsLower = labels.map { $0.lowercased() }

        if labelsLower.contains(where: { $0.contains("4k") || $0.contains("2160p") || $0.contains("uhd") }) {
            return .p4k
        }
        if labelsLower.contains(where: { $0.contains("2k") || $0.contains("1440p") }) {
            return .p2k
        }
        if labelsLower.contains(where: { $0.contains("1080p") || $0.contains("1080i") || $0.contains("fhd") }) {
            return .p1080
        }
        if labelsLower.contains(where: { $0.contains("720p") || $0.contains("720i") || $0.contains("hd") && !$0.contains("uhd") && !$0.contains("fhd") }) {
            return .p720
        }
        if labelsLower.contains(where: { $0.contains("sd") || $0.contains("480p") || $0.contains("576p") }) {
            return .sd
        }

        return .unknown
    }

    /// 从 standard 字段值提取分辨率
    static func fromStandard(_ standard: String?) -> Resolution {
        guard let code = standard else { return .unknown }

        // 根据 API 文档，standard 字段的映射
        switch code {
        case "6": return .p4k
        case "5": return .p2k
        case "4": return .p1080
        case "3": return .p720
        case "2", "1": return .sd
        default: return .unknown
        }
    }
}
