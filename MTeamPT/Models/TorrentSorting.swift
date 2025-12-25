import Foundation

// MARK: - Torrent 排序扩展

extension Torrent {

    // MARK: - 分辨率提取

    /// 从 labelsNew 和 standard 字段提取分辨率
    var resolution: Resolution {
        // 优先从 labelsNew 提取
        let resFromLabels = Resolution.fromLabels(labelsNew)
        if resFromLabels != .unknown {
            return resFromLabels
        }

        // 从 standard 字段提取
        return Resolution.fromStandard(standard)
    }

    // MARK: - 大小计算

    /// 总大小（字节）
    var sizeInBytes: Double {
        Double(size) ?? 0
    }

    /// 总大小（GB）
    var sizeInGB: Double {
        sizeInBytes / 1024 / 1024 / 1024
    }

    /// 文件数量
    var fileCount: Int {
        Int(numfiles) ?? 1
    }

    /// 平均每个文件的大小（GB）- 用于电视剧评估
    var averageFileSizeGB: Double {
        guard fileCount > 0 else { return sizeInGB }
        return sizeInGB / Double(fileCount)
    }

    // MARK: - 内容类型检测

    /// 是否为电视剧（根据文件数量判断，多文件通常是电视剧）
    var isTVShow: Bool {
        fileCount > 1
    }

    // MARK: - 推荐评分计算

    /// 计算推荐分数（越高越推荐，满分 100）
    var recommendationScore: Double {
        var score: Double = 0

        // 1. 大小评分（满分 50 分）
        score += sizeScore

        // 2. 分辨率评分（满分 30 分）
        score += resolutionScore

        // 3. 健康度评分（满分 20 分）
        score += healthScore

        return score
    }

    /// 大小评分（满分 50 分）
    private var sizeScore: Double {
        let idealSize: Double
        let actualSize: Double

        if isTVShow {
            // 电视剧：理想每集 2.5GB
            idealSize = 2.5
            actualSize = averageFileSizeGB
        } else {
            // 电影：理想 10GB
            idealSize = 10.0
            actualSize = sizeInGB
        }

        // 使用高斯函数计算偏离度
        // 偏离理想值越远，分数越低
        let deviation = abs(actualSize - idealSize) / idealSize

        // 偏离 0% -> 50分，偏离 100% -> 约 18分，偏离 200% -> 约 7分
        let score = 50.0 * exp(-pow(deviation, 2) / 0.5)

        return score
    }

    /// 分辨率评分（满分 30 分）
    private var resolutionScore: Double {
        switch resolution {
        case .p1080: return 30
        case .p2k: return 24
        case .p720: return 18
        case .p4k: return 10  // 4K 通常文件过大
        case .sd: return 6
        case .unknown: return 0
        }
    }

    /// 健康度评分（满分 20 分）
    private var healthScore: Double {
        guard let seedersStr = status.seeders,
              let seeders = Int(seedersStr) else { return 0 }

        // 种子数越多分数越高，但边际递减
        // 10个种子以上给满分
        return min(Double(seeders) * 2, 20)
    }

    // MARK: - 过大警告检测

    /// 是否超过推荐大小阈值
    var isOversized: Bool {
        if isTVShow {
            // 电视剧：单集 > 3GB
            return averageFileSizeGB > 3.0
        } else {
            // 电影：> 20GB
            return sizeInGB > 20.0
        }
    }

    /// 超大提示信息
    var oversizeWarningMessage: String? {
        guard isOversized else { return nil }

        if isTVShow {
            return "该资源单集大小约 \(String(format: "%.1f", averageFileSizeGB)) GB，超过推荐的 3GB，确定要选择吗？"
        } else {
            return "该资源大小约 \(String(format: "%.1f", sizeInGB)) GB，超过推荐的 20GB，确定要选择吗？"
        }
    }

    /// 是否为推荐资源（评分 >= 70）
    var isRecommended: Bool {
        recommendationScore >= 70
    }
}
