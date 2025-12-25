import SwiftUI

struct TorrentCardView: View {
    let torrent: Torrent
    @State private var isPressed = false
    
    // 格式化数字显示（大于1000显示为1k+格式）
    private func formatNumber(_ numStr: String) -> String {
        guard let num = Int(numStr) else { return numStr }
        if num >= 10000 {
            return "\(num / 1000)k"
        } else if num >= 1000 {
            return String(format: "%.1fk", Double(num) / 1000.0)
        }
        return numStr
    }
    
    var body: some View {
        cardContent
            .contentShape(Rectangle())
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部区域：标题和优惠/健康度标志
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    // 标题和时间
                    VStack(alignment: .leading, spacing: 4) {
                        Text(torrent.displayTitle)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(2)
                            .foregroundColor(.primary)
                        
                        // 发布时间
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 11))
                                .foregroundColor(torrent.createdTimeColor.opacity(0.8))
                            Text(torrent.relativeCreatedTime)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(torrent.createdTimeColor)
                        }
                    }
                    
                    // 大小和评分
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.circle")
                                .font(.caption)
                            Text(torrent.formattedSize)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        if let rating = torrent.displayRating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text(rating)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    labelsView

                    // 推荐/过大标签
                    recommendationBadge
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    if torrent.hasDiscount {
                        DiscountBadge(discountType: torrent.discountType)
                    }
                    
                    HealthIndicator(status: torrent.healthStatus)
                }
            }
            
            // 底部统计信息区域，添加分隔线
            Divider()
                .background(Color.secondary.opacity(0.1))
            
            HStack(spacing: 0) {
                // 上传/下载统计
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text(torrent.status.seeders ?? "0")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text(torrent.status.leechers ?? "0")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // 查看和完成统计
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 11))
                        Text(formatNumber(torrent.status.views ?? "0"))
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary.opacity(0.8))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                        Text(formatNumber(torrent.status.timesCompleted ?? "0"))
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary.opacity(0.8))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: torrent.createdDateAsDate?.timeIntervalSinceNow ?? -86400 > -3600 ? 
                                    [Color.green.opacity(0.2), Color.blue.opacity(0.2)] :
                                    [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
    
    private var labelsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(torrent.labelsNew.prefix(5), id: \.self) { label in
                    LabelChip(text: label)
                }

                if torrent.labelsNew.count > 5 {
                    Text("+\(torrent.labelsNew.count - 5)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6))
                        )
                }
            }
        }
    }

    @ViewBuilder
    private var recommendationBadge: some View {
        if torrent.isRecommended {
            HStack(spacing: 4) {
                Image(systemName: "hand.thumbsup.fill")
                    .font(.caption2)
                Text("推荐")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.green.opacity(0.15))
            )
        } else if torrent.isOversized {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption2)
                Text("较大")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.15))
            )
        }
    }
}

struct LabelChip: View {
    let text: String
    
    var backgroundColor: Color {
        switch text.lowercased() {
        case let t where t.contains("4k"):
            return .purple.opacity(0.15)
        case let t where t.contains("hdr"):
            return .orange.opacity(0.15)
        case let t where t.contains("中字"):
            return .blue.opacity(0.15)
        case let t where t.contains("中配"):
            return .green.opacity(0.15)
        case let t where t.contains("dolby"):
            return .red.opacity(0.15)
        default:
            return Color(.systemGray6)
        }
    }
    
    var foregroundColor: Color {
        switch text.lowercased() {
        case let t where t.contains("4k"):
            return .purple
        case let t where t.contains("hdr"):
            return .orange
        case let t where t.contains("中字"):
            return .blue
        case let t where t.contains("中配"):
            return .green
        case let t where t.contains("dolby"):
            return .red
        default:
            return .secondary
        }
    }
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
    }
}

struct DiscountBadge: View {
    let discountType: DiscountType
    
    var body: some View {
        Text(discountType.displayText)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: gradientColors[0].opacity(0.3), radius: 3, x: 0, y: 2)
    }
    
    private var gradientColors: [Color] {
        switch discountType {
        case .free, .twoXFree:
            return [.green, .green.opacity(0.8)]
        case .percent50, .percent30, .percent70:
            return [.blue, .blue.opacity(0.8)]
        case .twoX, .twoXPercent50:
            return [.orange, .orange.opacity(0.8)]
        default:
            return [.gray, .gray.opacity(0.8)]
        }
    }
}

struct HealthIndicator: View {
    let status: HealthStatus
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(status.description)
                .font(.caption2)
                .foregroundColor(color)
        }
    }
    
    private var iconName: String {
        switch status {
        case .excellent:
            return "heart.fill"
        case .good:
            return "heart.circle.fill"
        case .fair:
            return "heart"
        case .poor:
            return "heart.slash"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private var color: Color {
        switch status {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .yellow
        case .poor:
            return .red
        case .unknown:
            return .gray
        }
    }
}