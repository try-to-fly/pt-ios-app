import SwiftUI

struct TorrentCardView: View {
    let torrent: Torrent
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(torrent.name)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
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
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    if torrent.hasDiscount {
                        DiscountBadge(discountType: torrent.discountType)
                    }
                    
                    HealthIndicator(status: torrent.healthStatus)
                }
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(torrent.status.seeders ?? "0")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(torrent.status.leechers ?? "0")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "eye")
                        .font(.caption)
                    Text(torrent.status.views ?? "0")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                    Text(torrent.status.timesCompleted ?? "0")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.1),
                                    Color.purple.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(
            minimumDuration: 0.1,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: { }
        )
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
            return "heart.lefthalf.fill"
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